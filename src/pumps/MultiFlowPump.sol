// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IPump} from "src/interfaces/pumps/IPump.sol";
import {IMultiFlowPumpErrors} from "src/interfaces/pumps/IMultiFlowPumpErrors.sol";
import {IWell} from "src/interfaces/IWell.sol";
import {IInstantaneousPump} from "src/interfaces/pumps/IInstantaneousPump.sol";
import {ICumulativePump} from "src/interfaces/pumps/ICumulativePump.sol";
import {ABDKMathQuad} from "src/libraries/ABDKMathQuad.sol";
import {LibBytes16} from "src/libraries/LibBytes16.sol";
import {LibLastReserveBytes} from "src/libraries/LibLastReserveBytes.sol";

/**
 * @title MultiFlowPump
 * @author Brendan
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
contract MultiFlowPump is IPump, IMultiFlowPumpErrors, IInstantaneousPump, ICumulativePump {
    using LibLastReserveBytes for bytes32;
    using LibBytes16 for bytes32;
    using ABDKMathQuad for bytes16;
    using ABDKMathQuad for uint256;

    bytes16 public immutable LOG_MAX_INCREASE;
    bytes16 public immutable LOG_MAX_DECREASE;
    bytes16 public immutable ALPHA;
    uint256 public immutable CAP_INTERVAL;

    struct PumpState {
        uint40 lastTimestamp;
        bytes16[] lastReserves;
        bytes16[] emaReserves;
        bytes16[] cumulativeReserves;
    }

    /**
     * @param _maxPercentIncrease The maximum percent increase allowed in a single block. Must be in quadruple precision format (See {ABDKMathQuad}).
     * @param _maxPercentDecrease The maximum percent decrease allowed in a single block. Must be in quadruple precision format (See {ABDKMathQuad}).
     * @param _capInterval How often to increase the magnitude of the cap on the change in reserve in seconds.
     * @param _alpha The geometric EMA constant. Must be in quadruple precision format (See {ABDKMathQuad}).
     *
     * @dev The Pump will not flow and should definitely be considered invalid if the following constraints are not met:
     * - 0% < _maxPercentIncrease
     * - 0% < _maxPercentDecrease <= 100%
     * - 0 < ALPHA <= 1
     * - _capInterval > 0
     * The above constraints are not checked in the constructor for gas efficiency reasons.
     * When evaluating the manipulation resistance of an instance of a Multi Flow Pump for use as an oracle, stricter
     * constraints should be used.
     */
    constructor(bytes16 _maxPercentIncrease, bytes16 _maxPercentDecrease, uint256 _capInterval, bytes16 _alpha) {
        LOG_MAX_INCREASE = ABDKMathQuad.ONE.add(_maxPercentIncrease).log_2();
        LOG_MAX_DECREASE = ABDKMathQuad.ONE.sub(_maxPercentDecrease).log_2();
        CAP_INTERVAL = _capInterval;
        ALPHA = _alpha;
    }

    //////////////////// PUMP ////////////////////

    function update(uint256[] calldata reserves, bytes calldata) external {
        uint256 numberOfReserves = reserves.length;
        PumpState memory pumpState;

        // All reserves are stored starting at the msg.sender address slot in storage.
        bytes32 slot = _getSlotForAddress(msg.sender);

        // Read: Last Timestamp & Last Reserves
        (, pumpState.lastTimestamp, pumpState.lastReserves) = slot.readLastReserves();

        // If the last timestamp is 0, then the pump has never been used before.
        if (pumpState.lastTimestamp == 0) {
            _init(slot, uint40(block.timestamp), reserves);
            return;
        }

        bytes16 alphaN;
        bytes16 deltaTimestampBytes;
        bytes16 capExponent;
        // Isolate in brackets to prevent stack too deep errors
        {
            uint256 deltaTimestamp = _getDeltaTimestamp(pumpState.lastTimestamp);
            // If no time has passed, don't update the pump reserves.
            if (deltaTimestamp == 0) return;
            alphaN = ALPHA.powu(deltaTimestamp);
            deltaTimestampBytes = deltaTimestamp.fromUInt();
            // Round up in case CAP_INTERVAL > block time to guarantee capExponent > 0 if time has passed since the last update.
            capExponent = ((deltaTimestamp - 1) / CAP_INTERVAL + 1).fromUInt();
        }

        // Read: Cumulative & EMA Reserves
        // Start at the slot after `pumpState.lastReserves`
        uint256 numSlots = _getSlotsOffset(numberOfReserves);
        assembly {
            slot := add(slot, numSlots)
        }
        pumpState.emaReserves = slot.readBytes16(numberOfReserves);
        assembly {
            slot := add(slot, numSlots)
        }
        pumpState.cumulativeReserves = slot.readBytes16(numberOfReserves);

        uint256 _reserve;
        for (uint256 i; i < numberOfReserves; ++i) {
            // Use a minimum of 1 for reserve. Geometric means will be set to 0 if a reserve is 0.
            _reserve = reserves[i];
            pumpState.lastReserves[i] =
                _capReserve(pumpState.lastReserves[i], (_reserve > 0 ? _reserve : 1).fromUIntToLog2(), capExponent);
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
    function _init(bytes32 slot, uint40 lastTimestamp, uint256[] memory reserves) internal {
        uint256 numberOfReserves = reserves.length;
        bytes16[] memory byteReserves = new bytes16[](numberOfReserves);

        // Skip {_capReserve} since we have no prior reference

        for (uint256 i; i < numberOfReserves; ++i) {
            uint256 _reserve = reserves[i];
            if (_reserve == 0) return;
            byteReserves[i] = _reserve.fromUIntToLog2();
        }

        // Write: Last Timestamp & Last Reserves
        slot.storeLastReserves(lastTimestamp, byteReserves);

        // Write: EMA Reserves
        // Start at the slot after `byteReserves`
        uint256 numSlots = _getSlotsOffset(numberOfReserves);
        assembly {
            slot := add(slot, numSlots)
        }
        slot.storeBytes16(byteReserves); // EMA Reserves
    }

    //////////////////// LAST RESERVES ////////////////////

    /**
     * @dev Reads the last capped reserves from the Pump from storage.
     */
    function readLastCappedReserves(address well) public view returns (uint256[] memory lastCappedReserves) {
        (uint8 numberOfReserves,, bytes16[] memory lastReserves) = _getSlotForAddress(well).readLastReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
        lastCappedReserves = new uint256[](numberOfReserves);
        for (uint256 i; i < numberOfReserves; ++i) {
            lastCappedReserves[i] = lastReserves[i].pow_2ToUInt();
        }
    }

    /**
     * @dev Reads the capped reserves from the Pump updated to the current block using the current reserves of `well`.
     */
    function readCappedReserves(address well) external view returns (uint256[] memory cappedReserves) {
        bytes32 slot = _getSlotForAddress(well);
        uint256[] memory currentReserves = IWell(well).getReserves();
        (uint8 numberOfReserves, uint40 lastTimestamp, bytes16[] memory lastReserves) = slot.readLastReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
        uint256 deltaTimestamp = _getDeltaTimestamp(lastTimestamp);
        cappedReserves = new uint256[](numberOfReserves);
        if (deltaTimestamp == 0) {
            for (uint256 i; i < numberOfReserves; ++i) {
                cappedReserves[i] = lastReserves[i].pow_2ToUInt();
            }
            return cappedReserves;
        }

        bytes16 capExponent = ((deltaTimestamp - 1) / CAP_INTERVAL + 1).fromUInt();

        for (uint256 i; i < numberOfReserves; ++i) {
            cappedReserves[i] =
                _capReserve(lastReserves[i], currentReserves[i].fromUIntToLog2(), capExponent).pow_2ToUInt();
        }
    }

    /**
     * @dev Adds a cap to the reserve value to prevent extreme changes.
     *
     *  Linear space:
     *     max reserve = (last reserve) * ((1 + MAX_PERCENT_CHANGE_PER_BLOCK) ^ capExponent)
     *
     *  Log space:
     *     log2(max reserve) = log2(last reserve) + capExponent*log2(1 + MAX_PERCENT_CHANGE_PER_BLOCK)
     *
     *     `bytes16 lastReserve`      <- log2(last reserve)
     *     `bytes16 capExponent`      <- cap exponent
     *     `bytes16 LOG_MAX_INCREASE` <- log2(1 + MAX_PERCENT_CHANGE_PER_BLOCK)
     *
     *     ∴ `maxReserve = lastReserve + capExponent*LOG_MAX_INCREASE`
     *
     */
    function _capReserve(
        bytes16 lastReserve,
        bytes16 reserve,
        bytes16 capExponent
    ) internal view returns (bytes16 cappedReserve) {
        // Reserve decreasing (lastReserve > reserve)
        if (lastReserve.cmp(reserve) == 1) {
            bytes16 minReserve = lastReserve.add(capExponent.mul(LOG_MAX_DECREASE));
            // if reserve < minimum reserve, set reserve to minimum reserve
            if (minReserve.cmp(reserve) == 1) reserve = minReserve;
        }
        // Reserve increasing or staying the same (lastReserve <= reserve)
        else {
            bytes16 maxReserve = lastReserve.add(capExponent.mul(LOG_MAX_INCREASE));
            // If reserve > maximum reserve, set reserve to maximum reserve
            if (reserve.cmp(maxReserve) == 1) reserve = maxReserve;
        }
        cappedReserve = reserve;
    }

    //////////////////// EMA RESERVES ////////////////////

    function readLastInstantaneousReserves(address well) external view returns (uint256[] memory emaReserves) {
        bytes32 slot = _getSlotForAddress(well);
        uint8 numberOfReserves = slot.readNumberOfReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
        uint256 offset = _getSlotsOffset(numberOfReserves);
        assembly {
            slot := add(slot, offset)
        }
        bytes16[] memory byteReserves = slot.readBytes16(numberOfReserves);
        emaReserves = new uint256[](numberOfReserves);
        for (uint256 i; i < numberOfReserves; ++i) {
            emaReserves[i] = byteReserves[i].pow_2ToUInt();
        }
    }

    function readInstantaneousReserves(
        address well,
        bytes memory
    ) external view returns (uint256[] memory emaReserves) {
        bytes32 slot = _getSlotForAddress(well);
        uint256[] memory reserves = IWell(well).getReserves();
        (uint8 numberOfReserves, uint40 lastTimestamp, bytes16[] memory lastReserves) = slot.readLastReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
        uint256 offset = _getSlotsOffset(numberOfReserves);
        assembly {
            slot := add(slot, offset)
        }
        bytes16[] memory lastEmaReserves = slot.readBytes16(numberOfReserves);
        uint256 deltaTimestamp = _getDeltaTimestamp(lastTimestamp);
        emaReserves = new uint256[](numberOfReserves);
        // If no time has passed, return last EMA reserves.
        if (deltaTimestamp == 0) {
            for (uint256 i; i < numberOfReserves; ++i) {
                emaReserves[i] = lastEmaReserves[i].pow_2ToUInt();
            }
            return emaReserves;
        }
        bytes16 capExponent = ((deltaTimestamp - 1) / CAP_INTERVAL + 1).fromUInt();
        bytes16 alphaN = ALPHA.powu(deltaTimestamp);
        for (uint256 i; i < numberOfReserves; ++i) {
            lastReserves[i] = _capReserve(lastReserves[i], reserves[i].fromUIntToLog2(), capExponent);
            emaReserves[i] =
                lastReserves[i].mul((ABDKMathQuad.ONE.sub(alphaN))).add(lastEmaReserves[i].mul(alphaN)).pow_2ToUInt();
        }
    }

    //////////////////// CUMULATIVE RESERVES ////////////////////

    /**
     * @notice Read the latest cumulative reserves of `well`.
     */
    function readLastCumulativeReserves(address well) external view returns (bytes16[] memory cumulativeReserves) {
        bytes32 slot = _getSlotForAddress(well);
        uint8 numberOfReserves = slot.readNumberOfReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
        uint256 offset = _getSlotsOffset(numberOfReserves) << 1;
        assembly {
            slot := add(slot, offset)
        }
        cumulativeReserves = slot.readBytes16(numberOfReserves);
    }

    function readCumulativeReserves(
        address well,
        bytes memory
    ) external view returns (bytes memory cumulativeReserves) {
        bytes16[] memory byteCumulativeReserves = _readCumulativeReserves(well);
        cumulativeReserves = abi.encode(byteCumulativeReserves);
    }

    function _readCumulativeReserves(address well) internal view returns (bytes16[] memory cumulativeReserves) {
        bytes32 slot = _getSlotForAddress(well);
        uint256[] memory reserves = IWell(well).getReserves();
        (uint8 numberOfReserves, uint40 lastTimestamp, bytes16[] memory lastReserves) = slot.readLastReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
        uint256 offset = _getSlotsOffset(numberOfReserves) << 1;
        assembly {
            slot := add(slot, offset)
        }
        cumulativeReserves = slot.readBytes16(numberOfReserves);
        uint256 deltaTimestamp = _getDeltaTimestamp(lastTimestamp);
        // If no time has passed, return last cumulative reserves.
        if (deltaTimestamp == 0) {
            return cumulativeReserves;
        }
        bytes16 deltaTimestampBytes = deltaTimestamp.fromUInt();
        bytes16 capExponent = ((deltaTimestamp - 1) / CAP_INTERVAL + 1).fromUInt();
        // Currently, there is so support for overflow.
        for (uint256 i; i < cumulativeReserves.length; ++i) {
            lastReserves[i] = _capReserve(lastReserves[i], reserves[i].fromUIntToLog2(), capExponent);
            cumulativeReserves[i] = cumulativeReserves[i].add(lastReserves[i].mul(deltaTimestampBytes));
        }
    }

    function readTwaReserves(
        address well,
        bytes calldata startCumulativeReserves,
        uint256 startTimestamp,
        bytes memory
    ) public view returns (uint256[] memory twaReserves, bytes memory cumulativeReserves) {
        bytes16[] memory byteCumulativeReserves = _readCumulativeReserves(well);
        bytes16[] memory byteStartCumulativeReserves = abi.decode(startCumulativeReserves, (bytes16[]));
        twaReserves = new uint256[](byteCumulativeReserves.length);

        // Overflow is desired on `startTimestamp`, so SafeCast is not used.
        bytes16 deltaTimestamp = _getDeltaTimestamp(uint40(startTimestamp)).fromUInt();
        if (deltaTimestamp == bytes16(0)) {
            revert NoTimePassed();
        }
        for (uint256 i; i < byteCumulativeReserves.length; ++i) {
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
    function _getSlotForAddress(address addressValue) internal pure returns (bytes32 _slot) {
        _slot = bytes32(bytes20(addressValue)); // Because right padded, no collision on adjacent
    }

    /**
     * @dev Get the starting byte of the slot that contains the `n`th element of an array.
     */
    function _getSlotsOffset(uint256 numberOfReserves) internal pure returns (uint256 _slotsOffset) {
        _slotsOffset = ((numberOfReserves - 1) / 2 + 1) << 5;
    }

    /**
     * @dev Get the delta between the current and provided timestamp as a `uint256`.
     */
    function _getDeltaTimestamp(uint40 lastTimestamp) internal view returns (uint256 _deltaTimestamp) {
        return uint256(uint40(block.timestamp) - lastTimestamp);
    }
}
