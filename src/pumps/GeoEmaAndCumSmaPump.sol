// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "src/interfaces/pumps/IPump.sol";
import "src/interfaces/pumps/IInstantaneousPump.sol";
import "src/interfaces/pumps/ICumulativePump.sol";
import "src/libraries/ABDKMathQuad.sol";
import "src/libraries/LibBytes16.sol";
import "src/libraries/LibLastReserveBytes.sol";
import "oz/utils/math/SafeCast.sol";

// TODO: Remove this import
import "forge-std/console.sol";

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
 */
contract GeoEmaAndCumSmaPump is IPump, IInstantaneousPump, ICumulativePump {
    using SafeCast for uint;
    using LibLastReserveBytes for bytes32;
    using LibBytes16 for bytes32;
    using ABDKMathQuad for bytes16;
    using ABDKMathQuad for uint;

    bytes16 immutable LOG_MAX_INCREASE;
    bytes16 immutable LOG_MAX_DECREASE;
    bytes16 immutable A;
    uint immutable BLOCK_TIME;

    struct Reserves {
        uint40 lastTimestamp;
        bytes16[] lastReserves;
        bytes16[] emaReserves;
        bytes16[] cumulativeReserves;
    }

    /**
     * @param _maxPercentChange The maximum percent change allowed in a single block. 18 decimal precision.
     * @param _blockTime The block time in the current EVM in seconds.
     * @param _A The geometric EMA constant. 0.9994445987e18 is a good value.
     */
    constructor(
        bytes16 _maxPercentChange,
        uint _blockTime,
        bytes16 _A
    ) {
        LOG_MAX_INCREASE = ABDKMathQuad.ONE.add(_maxPercentChange).log_2();
        LOG_MAX_DECREASE = ABDKMathQuad.ONE.sub(_maxPercentChange).log_2();
        BLOCK_TIME = _blockTime;
        A = _A;
    }

    function attach(uint _n, bytes calldata pumpData) external {}

    function update(uint[] calldata reserves, bytes calldata) external {
        Reserves memory b;

        // All reserves are stored starting at the msg.sender address
        bytes32 slot = fillLast12Bytes(msg.sender);

        // Read: Last Timestamp & Last Reserves
        (, b.lastTimestamp, b.lastReserves) = slot.readLastReserves();

        // TODO: Finalize init condition. timestamp? lastReserve?
        if (b.lastTimestamp == 0) {
            initPump(slot, uint40(block.timestamp), reserves);
            return;
        }

        // Read: Cumulative & EMA Reserves
        // Start at the slot after `b.lastReserves`
        uint numSlots = getSlotsOffset(reserves.length);
        assembly { slot := add(slot, numSlots) }
        b.emaReserves = slot.readBytes16(reserves.length);
        assembly { slot := add(slot, numSlots) }
        b.cumulativeReserves = slot.readBytes16(reserves.length);

        uint deltaTimestamp = getDeltaTimestamp(b.lastTimestamp);
        bytes16 aN = A.powu(deltaTimestamp);
        bytes16 deltaTimestampBytes = deltaTimestamp.fromUInt();
        // TODO: Check if cheaper to use DeltaTimestampBytes
        // TODO: Always require > 1 ???? Round up ????? `Look into timestamp manipulation
        bytes16 blocksPassed = (deltaTimestamp / BLOCK_TIME).fromUInt();

        for (uint i = 0; i < reserves.length; i++) {
            b.lastReserves[i] = capReserve(
                b.lastReserves[i],
                reserves[i].fromUInt().log_2(),
                blocksPassed
            );
            b.emaReserves[i] = 
                b.lastReserves[i].mul((ABDKMathQuad.ONE.sub(aN))).add(b.emaReserves[i].mul(aN));
            b.cumulativeReserves[i] = b.cumulativeReserves[i].add(b.lastReserves[i].mul(deltaTimestampBytes));
        }

        // Write: Cumulative & EMA Reserves
        // Order matters: work backwards to avoid using a new memory var to count up
        slot.storeBytes16(b.cumulativeReserves);
        assembly { slot := sub(slot, numSlots) }
        slot.storeBytes16(b.emaReserves);
        assembly { slot := sub(slot, numSlots) }

        // Write: Last Timestamp & Last Reserves
        slot.storeLastReserves(uint40(block.timestamp), b.lastReserves);
    }

    // General Helpers

    function initPump(
        bytes32 slot,
        uint40 lastTimestamp,
        uint[] memory reserves
    ) internal {
        bytes16[] memory byteReserves = new bytes16[](reserves.length);
        for (uint i = 0; i < reserves.length; i++) {
            byteReserves[i] = reserves[i].fromUInt().log_2();
        }
        slot.storeLastReserves(lastTimestamp, byteReserves);
        uint numSlots = getSlotsOffset(byteReserves.length);
        assembly { slot := add(slot, numSlots) }
        slot.storeBytes16(byteReserves); // EMA Reserves
    }

    /**
     * @dev Convert an `address` into a `bytes32` by zero padding the right 12 bytes.
     */
    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }

    /**
     * @dev Get the starting byte of the slot that contains the `n`th element of an array.
     */
    function getSlotsOffset(uint n) internal pure returns (uint) {
        return ((n - 1) / 2 + 1) * 32;
    }

    function getDeltaTimestamp(uint40 lastTimestamp) public view returns (uint) {
        return uint(uint40(block.timestamp) - lastTimestamp);
    }

    /**
     * Last Reserves
     */

    function capReserve(
        bytes16 lastReserve,
        bytes16 reserve,
        bytes16 blocksPassed
    ) internal view returns (bytes16 cappedReserve) {
        if (reserve < lastReserve) {
            bytes16 minReserve = lastReserve.add(blocksPassed.mul(LOG_MAX_DECREASE));
            if (reserve < minReserve) reserve = minReserve;
        } else {
            bytes16 maxReserve = blocksPassed.mul(LOG_MAX_INCREASE);
            maxReserve = lastReserve.add(maxReserve);
            if (reserve > maxReserve) reserve = maxReserve;
        }
        cappedReserve = reserve;
    }

    function readLastReserves(address well) public view returns (uint[] memory reserves) {
        bytes32 slot = fillLast12Bytes(well);
        (, , bytes16[] memory bytesReserves) = slot.readLastReserves();
        reserves = new uint[](bytesReserves.length);
        for (uint i = 0; i < reserves.length; i++) {
            reserves[i] = bytesReserves[i].pow_2().toUInt();
        }
    }

    /**
     * EMA Reserves
     */

    function readLastInstantaneousReserves(address well) public view returns (uint[] memory reserves) {
        bytes32 slot = fillLast12Bytes(well);
        uint8 n = slot.readN();
        uint offset = getSlotsOffset(n);
        assembly { slot := add(slot, offset) }
        bytes16[] memory byteReserves = slot.readBytes16(n);
        reserves = new uint[](n);
        for (uint i = 0; i < reserves.length; i++) {
            reserves[i] = byteReserves[i].pow_2().toUInt();
        }
    }

    function readInstantaneousReserves(address well) public view returns (uint[] memory reserves) {
        bytes32 slot = fillLast12Bytes(well);
        (uint8 n, uint40 lastTimestamp, bytes16[] memory lastReserves) = slot.readLastReserves();
        uint offset = getSlotsOffset(n);
        assembly { slot := add(slot, offset) }
        bytes16[] memory lastEmaReserves = slot.readBytes16(n);
        uint deltaTimestamp = getDeltaTimestamp(lastTimestamp);
        bytes16 aN = A.powu(deltaTimestamp);
        reserves = new uint[](n);
        for (uint i = 0; i < reserves.length; i++) {
            reserves[i] = 
                lastReserves[i].mul((ABDKMathQuad.ONE.sub(aN))).add(lastEmaReserves[i].mul(aN)).pow_2().toUInt();
        }
    }

    /**
     * Cumulative Reserves
     */

    function readLastCumulativeReserves(address well)
        public
        view
        returns (bytes16[] memory reserves)
    {
        bytes32 slot = fillLast12Bytes(well);
        uint8 n = slot.readN();
        uint offset = getSlotsOffset(n) * 2;
        assembly {
            slot := add(slot, offset)
        }
        reserves = slot.readBytes16(n);
    }

    function readCumulativeReserves(address well)
        public
        view
        returns (bytes memory cumulativeReserves)
    {
        bytes16[] memory byteCumulativeReserves = _readCumulativeReserves(well);
        cumulativeReserves = abi.encode(byteCumulativeReserves);
    }

    function _readCumulativeReserves(address well)
        public
        view
        returns (bytes16[] memory cumulativeReserves)
    {
        bytes32 slot = fillLast12Bytes(well);
        (uint8 n, uint40 lastTimestamp, bytes16[] memory lastReserves) = slot.readLastReserves();
        uint offset = getSlotsOffset(n) * 2;
        assembly { slot := add(slot, offset) }
        cumulativeReserves = slot.readBytes16(n);
        bytes16 deltaTimestamp = getDeltaTimestamp(lastTimestamp).fromUInt();
        // TODO: Overflow desired ????
        for (uint i = 0; i < cumulativeReserves.length; i++) {
            cumulativeReserves[i] = cumulativeReserves[i].add(
                lastReserves[i].mul(deltaTimestamp)
            );
            }
    }

    function readTwaReserves(
        address well,
        bytes calldata startCumulativeReserves,
        uint startTimestamp
    ) public view returns (uint[] memory twaReserves, bytes memory cumulativeReserves) {
        bytes16[] memory byteCumulativeReserves = _readCumulativeReserves(well);
        bytes16[] memory byteStartCumulativeReserves = abi.decode(startCumulativeReserves, (bytes16[]));
        twaReserves = new uint[](cumulativeReserves.length);
        bytes16 deltaTimestamp = getDeltaTimestamp(uint40(startTimestamp)).fromUInt(); // TODO: Verify no safe cast is desired
        for (uint i = 0; i < cumulativeReserves.length; i++) {
            // TODO: Unchecked?
            twaReserves[i] = (byteCumulativeReserves[i].sub(byteStartCumulativeReserves[i])).div(deltaTimestamp).pow_2().toUInt();
        }
    }

    // TODO
    function read(address well, bytes calldata readData) external view returns (bytes memory data) {}
}
