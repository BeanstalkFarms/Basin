// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IPump} from "src/interfaces/pumps/IPump.sol";
import {IGeoEmaAndCumSmaPumpErrors} from "src/interfaces/pumps/IGeoEmaAndCumSmaPumpErrors.sol";
import {IWell} from "src/interfaces/IWell.sol";
import {IInstantaneousPump} from "src/interfaces/pumps/IInstantaneousPump.sol";
import {ICumulativePump} from "src/interfaces/pumps/ICumulativePump.sol";
import {ABDKMathQuad} from "src/libraries/ABDKMathQuad.sol";
import {LibBytes16} from "src/libraries/LibBytes16.sol";
import {LibLastReserveBytes} from "src/libraries/LibLastReserveBytes.sol";
import {SafeCast} from "oz/utils/math/SafeCast.sol";

/**
 * @title GeoEmaAndCumSmaPump
 * @author Publius
 * @notice Stores a geometric EMA and cumulative geometric SMA for each reserve.
 * @dev A Pump designed for use in Beanstalk with 2 tokens.
 *
 * This Pump has 3 main features:
 *  1. Multi-block MEV resistence reserves
 *  2. MEV-resistant Geometric EMA intended for instantaneous reserve queries
 *  3. MEV-resistant Cumulative Geometric intended for SMA reserve queries
 *
 * Note: If an `update` call is made with a reserve of 0, the Geometric mean oracles will be set to 0.
 * Each Well is responsible for ensuring that an `update` call cannot be made with a reserve of 0.
 */
contract GeoEmaAndCumSmaPump is IPump, IGeoEmaAndCumSmaPumpErrors, IInstantaneousPump, ICumulativePump {
    using SafeCast for uint;
    using LibLastReserveBytes for bytes32;
    using LibBytes16 for bytes32;
    using ABDKMathQuad for bytes16;
    using ABDKMathQuad for uint;

    bytes16 immutable LOG_MAX_INCREASE;
    bytes16 immutable LOG_MAX_DECREASE;
    bytes16 immutable ALPHA;
    uint immutable BLOCK_TIME;

    struct PumpState {
        uint40 lastTimestamp;
        bytes16[] lastReserves;
        bytes16[] emaReserves;
        bytes16[] cumulativeReserves;
    }

    /**
     * @param _maxPercentIncrease The maximum percent increase allowed in a single block. Must be in quadruple precision format (See {ABDKMathQuad}).
     * @param _maxPercentDecrease The maximum percent decrease allowed in a single block. Must be in quadruple precision format (See {ABDKMathQuad}).
     * @param _blockTime The block time in the current EVM in seconds.
     * @param _alpha The geometric EMA constant. Must be in quadruple precision format (See {ABDKMathQuad}).
     */
    constructor(bytes16 _maxPercentIncrease, bytes16 _maxPercentDecrease, uint _blockTime, bytes16 _alpha) {
        LOG_MAX_INCREASE = ABDKMathQuad.ONE.add(_maxPercentIncrease).log_2();
        // _maxPercentDecrease <= 100%
        if (_maxPercentDecrease > ABDKMathQuad.ONE) {
            revert InvalidMaxPercentDecreaseArgument(_maxPercentDecrease);
        }
        LOG_MAX_DECREASE = ABDKMathQuad.ONE.sub(_maxPercentDecrease).log_2();
        BLOCK_TIME = _blockTime;

        // ALPHA <= 1
        if (_alpha > ABDKMathQuad.ONE) {
            revert InvalidAArgument(_alpha);
        }
        ALPHA = _alpha;
    }

    //////////////////// PUMP ////////////////////

    function update(uint[] calldata reserves, bytes calldata) external {
        uint numberOfReserves = reserves.length;
        PumpState memory pumpState;

        // All reserves are stored starting at the msg.sender address slot in storage.
        bytes32 slot = _getSlotForAddress(msg.sender);

        // Read: Last Timestamp & Last Reserves
        (, pumpState.lastTimestamp, pumpState.lastReserves) = slot.readLastReserves();

        // If the last timestamp is 0, then the pump has never been used before.
        if (pumpState.lastTimestamp == 0) {
            for (uint i; i < numberOfReserves; ++i) {
                // If a reserve is 0, then the pump cannot be initialized.
                if (reserves[i] == 0) return;
            }
            _init(slot, uint40(block.timestamp), reserves);
            return;
        }

        // Read: Cumulative & EMA Reserves
        // Start at the slot after `pumpState.lastReserves`
        uint numSlots = _getSlotsOffset(numberOfReserves);
        assembly {
            slot := add(slot, numSlots)
        }
        pumpState.emaReserves = slot.readBytes16(numberOfReserves);
        assembly {
            slot := add(slot, numSlots)
        }
        pumpState.cumulativeReserves = slot.readBytes16(numberOfReserves);

        bytes16 alphaN;
        bytes16 deltaTimestampBytes;
        bytes16 blocksPassed;
        // Isolate in brackets to prevent stack too deep errors
        {
            uint deltaTimestamp = _getDeltaTimestamp(pumpState.lastTimestamp);
            alphaN = ALPHA.powu(deltaTimestamp);
            deltaTimestampBytes = deltaTimestamp.fromUInt();
            // Relies on the assumption that a block can only occur every `BLOCK_TIME` seconds.
            blocksPassed = (deltaTimestamp / BLOCK_TIME).fromUInt();
        }

        for (uint i; i < numberOfReserves; ++i) {
            // Use a minimum of 1 for reserve. Geometric means will be set to 0 if a reserve is 0.
            pumpState.lastReserves[i] = _capReserve(
                pumpState.lastReserves[i], (reserves[i] > 0 ? reserves[i] : 1).fromUIntToLog2(), blocksPassed
            );
            pumpState.emaReserves[i] =
                pumpState.lastReserves[i].mul((ABDKMathQuad.ONE.sub(alphaN))).add(pumpState.emaReserves[i].mul(alphaN));
            pumpState.cumulativeReserves[i] =
                pumpState.cumulativeReserves[i].add(pumpState.lastReserves[i].mul(deltaTimestampBytes));
        }

        // Write: Cumulative & EMA Reserves
        // Order matters: work backwards to avoid using a new memory var to count up
        slot.storeBytes16(pumpState.cumulativeReserves);
        assembly {
            slot := sub(slot, numSlots)
        }
        slot.storeBytes16(pumpState.emaReserves);
        assembly {
            slot := sub(slot, numSlots)
        }

        // Write: Last Timestamp & Last Reserves
        slot.storeLastReserves(uint40(block.timestamp), pumpState.lastReserves);
    }

    /**
     * @dev On first update for a particular Well, initialize oracle with
     * reserves data.
     */
    function _init(bytes32 slot, uint40 lastTimestamp, uint[] memory reserves) internal {
        uint numberOfReserves = reserves.length;
        bytes16[] memory byteReserves = new bytes16[](numberOfReserves);

        // Skip {_capReserve} since we have no prior reference

        for (uint i = 0; i < numberOfReserves; ++i) {
            if (reserves[i] == 0) return;
            byteReserves[i] = reserves[i].fromUIntToLog2();
        }

        // Write: Last Timestamp & Last Reserves
        slot.storeLastReserves(lastTimestamp, byteReserves);

        // Write: EMA Reserves
        // Start at the slot after `byteReserves`
        uint numSlots = _getSlotsOffset(byteReserves.length);
        assembly {
            slot := add(slot, numSlots)
        }
        slot.storeBytes16(byteReserves); // EMA Reserves
    }

    //////////////////// LAST RESERVES ////////////////////

    function readLastReserves(address well) public view returns (uint[] memory reserves) {
        bytes32 slot = _getSlotForAddress(well);
        (uint8 numberOfReserves,, bytes16[] memory bytesReserves) = slot.readLastReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
        reserves = new uint[](numberOfReserves);
        for (uint i = 0; i < numberOfReserves; ++i) {
            reserves[i] = bytesReserves[i].pow_2ToUInt();
        }
    }

    /**
     * @dev Adds a cap to the reserve value to prevent extreme changes.
     *
     *  Linear space:
     *     max reserve = (last reserve) * ((1 + MAX_PERCENT_CHANGE_PER_BLOCK) ^ blocks)
     *
     *  Log space:
     *     log2(max reserve) = log2(last reserve) + blocks*log2(1 + MAX_PERCENT_CHANGE_PER_BLOCK)
     *
     *     `bytes16 lastReserve`      <- log2(last reserve)
     *     `bytes16 blocksPassed`     <- log2(blocks)
     *     `bytes16 LOG_MAX_INCREASE` <- log2(1 + MAX_PERCENT_CHANGE_PER_BLOCK)
     *
     *     ∴ `maxReserve = lastReserve + blocks*LOG_MAX_INCREASE`
     *
     */
    function _capReserve(
        bytes16 lastReserve,
        bytes16 reserve,
        bytes16 blocksPassed
    ) internal view returns (bytes16 cappedReserve) {
        // Reserve decreasing (lastReserve > reserve)
        if (lastReserve.cmp(reserve) == 1) {
            bytes16 minReserve = lastReserve.add(blocksPassed.mul(LOG_MAX_DECREASE));
            // if reserve < minimum reserve, set reserve to minimum reserve
            if (minReserve.cmp(reserve) == 1) reserve = minReserve;
        }
        // Rerserve Increasing or staying the same.
        else {
            bytes16 maxReserve = blocksPassed.mul(LOG_MAX_INCREASE);
            maxReserve = lastReserve.add(maxReserve);
            // If reserve > maximum reserve, set reserve to maximum reserve
            if (reserve.cmp(maxReserve) == 1) reserve = maxReserve;
        }
        cappedReserve = reserve;
    }

    //////////////////// EMA RESERVES ////////////////////

    function readLastInstantaneousReserves(address well) public view returns (uint[] memory reserves) {
        bytes32 slot = _getSlotForAddress(well);
        uint8 numberOfReserves = slot.readNumberOfReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
        uint offset = _getSlotsOffset(numberOfReserves);
        assembly {
            slot := add(slot, offset)
        }
        bytes16[] memory byteReserves = slot.readBytes16(numberOfReserves);
        reserves = new uint[](numberOfReserves);
        for (uint i = 0; i < numberOfReserves; ++i) {
            reserves[i] = byteReserves[i].pow_2ToUInt();
        }
    }

    function readInstantaneousReserves(address well, bytes memory) public view returns (uint[] memory emaReserves) {
        bytes32 slot = _getSlotForAddress(well);
        uint[] memory reserves = IWell(well).getReserves();
        (uint8 numberOfReserves, uint40 lastTimestamp, bytes16[] memory lastReserves) = slot.readLastReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
        uint offset = _getSlotsOffset(numberOfReserves);
        assembly {
            slot := add(slot, offset)
        }
        bytes16[] memory lastEmaReserves = slot.readBytes16(numberOfReserves);
        uint deltaTimestamp = _getDeltaTimestamp(lastTimestamp);
        bytes16 blocksPassed = (deltaTimestamp / BLOCK_TIME).fromUInt();
        bytes16 alphaN = ALPHA.powu(deltaTimestamp);
        emaReserves = new uint[](numberOfReserves);
        for (uint i = 0; i < numberOfReserves; ++i) {
            lastReserves[i] = _capReserve(lastReserves[i], reserves[i].fromUIntToLog2(), blocksPassed);
            emaReserves[i] =
                lastReserves[i].mul((ABDKMathQuad.ONE.sub(alphaN))).add(lastEmaReserves[i].mul(alphaN)).pow_2ToUInt();
        }
    }

    //////////////////// CUMULATIVE RESERVES ////////////////////

    /**
     * @notice Read the latest cumulative reserves of `well`.
     */
    function readLastCumulativeReserves(address well) public view returns (bytes16[] memory reserves) {
        bytes32 slot = _getSlotForAddress(well);
        uint8 numberOfReserves = slot.readNumberOfReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
        uint offset = _getSlotsOffset(numberOfReserves) << 1;
        assembly {
            slot := add(slot, offset)
        }
        reserves = slot.readBytes16(numberOfReserves);
    }

    function readCumulativeReserves(address well, bytes memory) public view returns (bytes memory cumulativeReserves) {
        bytes16[] memory byteCumulativeReserves = _readCumulativeReserves(well);
        cumulativeReserves = abi.encode(byteCumulativeReserves);
    }

    function _readCumulativeReserves(address well) internal view returns (bytes16[] memory cumulativeReserves) {
        bytes32 slot = _getSlotForAddress(well);
        uint[] memory reserves = IWell(well).getReserves();
        (uint8 numberOfReserves, uint40 lastTimestamp, bytes16[] memory lastReserves) = slot.readLastReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
        uint offset = _getSlotsOffset(numberOfReserves) << 1;
        assembly {
            slot := add(slot, offset)
        }
        cumulativeReserves = slot.readBytes16(numberOfReserves);
        uint deltaTimestamp = _getDeltaTimestamp(lastTimestamp);
        bytes16 deltaTimestampBytes = deltaTimestamp.fromUInt();
        bytes16 blocksPassed = (deltaTimestamp / BLOCK_TIME).fromUInt();
        // Currently, there is so support for overflow.
        for (uint i = 0; i < cumulativeReserves.length; ++i) {
            lastReserves[i] = _capReserve(lastReserves[i], reserves[i].fromUIntToLog2(), blocksPassed);
            cumulativeReserves[i] = cumulativeReserves[i].add(lastReserves[i].mul(deltaTimestampBytes));
        }
    }

    function readTwaReserves(
        address well,
        bytes calldata startCumulativeReserves,
        uint startTimestamp,
        bytes memory
    ) public view returns (uint[] memory twaReserves, bytes memory cumulativeReserves) {
        bytes16[] memory byteCumulativeReserves = _readCumulativeReserves(well);
        bytes16[] memory byteStartCumulativeReserves = abi.decode(startCumulativeReserves, (bytes16[]));
        twaReserves = new uint[](byteCumulativeReserves.length);

        // Overflow is desired on `startTimestamp`, so SafeCast is not used.
        bytes16 deltaTimestamp = _getDeltaTimestamp(uint40(startTimestamp)).fromUInt();
        if (deltaTimestamp == bytes16(0)) {
            revert NoTimePassed();
        }
        for (uint i = 0; i < byteCumulativeReserves.length; ++i) {
            // Currently, there is no support for overflow.
            twaReserves[i] =
                (byteCumulativeReserves[i].sub(byteStartCumulativeReserves[i])).div(deltaTimestamp).pow_2ToUInt();
        }
        cumulativeReserves = abi.encode(byteCumulativeReserves);
    }

    //////////////////// HELPERS ////////////////////

    /**
     * @dev Convert an `address` into a `bytes32` by zero padding the right 12 bytes.
     */
    function _getSlotForAddress(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue)); // Because right padded, no collision on adjacent
    }

    /**
     * @dev Get the starting byte of the slot that contains the `n`th element of an array.
     */
    function _getSlotsOffset(uint numberOfReserves) internal pure returns (uint) {
        return ((numberOfReserves - 1) / 2 + 1) << 5;
    }

    /**
     * @dev Get the delta between the current and provided timestamp as a `uint256`.
     */
    function _getDeltaTimestamp(uint40 lastTimestamp) internal view returns (uint) {
        return uint(uint40(block.timestamp) - lastTimestamp);
    }
}
