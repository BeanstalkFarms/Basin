/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "src/interfaces/IPump.sol";
import "src/interfaces/pumps/IInstantaneousPump.sol";
import "src/interfaces/pumps/ICumulativePump.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";
import {log2 as slog2, wrap as swrap, unwrap as sunwrap} from "prb/math/SD59x18.sol";
import "src/libraries/LibBytes.sol";
import "src/libraries/LibLastReserveBytes.sol";
import "oz/utils/math/SafeCast.sol";

/**
 * @author Publius
 * @title Beanstalk Pump intended for use in Beanstalk.
 * @dev
 * A Pump designed for use in Beanstalk with 2 tokens.
 * This Pump has 3 main features:
 * 1. Multi-block MEV resistence reserves
 * 2. MEV-resistant Geometric EMA intended for instantaneous reserve queries
 * 3. MEV-resistant Cumulative Geometric intended for SMA reserve queries
 **/
contract BeanstalkPump is IPump, IInstantaneousPump, ICumulativePump {
    using SafeCast for uint;
    using LibLastReserveBytes for bytes32;
    using LibBytes for bytes32;

    uint immutable LOG_MAX_INCREASE;
    uint immutable LOG_MAX_DECREASE;
    uint immutable BLOCK_TIME;
    UD60x18 immutable A;

    struct Reserves {
        uint40 lastTimestamp;
        uint[] lastReserves;
        uint[] emaReserves;
        uint[] cumulativeReserves;
    }

    /**
     * @param _maxPercentChange The maximum percent change allowed in a single block. 18 decimal precision.
     * @param _blockTime The block time in the current EVM in seconds.
     * @param _A The geometric EMA constant. 0.9994445987e18 is a good value.
     */

    constructor(
        uint _maxPercentChange,
        uint _blockTime,
        uint _A
    ) {
        LOG_MAX_INCREASE = unwrap(log2(wrap(uUNIT + _maxPercentChange)));
        LOG_MAX_DECREASE = uint(
            -sunwrap(slog2(swrap((uUNIT - _maxPercentChange).toInt256())))
        );
        BLOCK_TIME = _blockTime;
        A = wrap(_A);
    }

    function attach(uint _n, bytes calldata pumpData) external {}

    function update(uint[] calldata reserves, bytes calldata) external {
        Reserves memory b;
        // All reserves are stored starting at the msg.sender address
        bytes32 slot = fillLast12Bytes(msg.sender);
        (, b.lastTimestamp, b.lastReserves) = slot.readLastReserves();
        // TODO: Finalize init condition. timestamp? lastReserve?
        if (b.lastTimestamp == 0) {
            initPump(slot, uint40(block.timestamp), reserves);
            return;
        }

        uint numSlots = getSlotsOffset(reserves.length);
        assembly { slot := add(slot, numSlots) }
        b.emaReserves = slot.readUint128(reserves.length);
        assembly { slot := add(slot, numSlots) }
        b.cumulativeReserves = slot.readUint128(reserves.length);

        uint deltaTimestamp = getDeltaTimestamp(b.lastTimestamp);
        uint blocksPassed = deltaTimestamp / BLOCK_TIME;
        uint aN = unwrap(powu(A, deltaTimestamp));

        for (uint i = 0; i < reserves.length; i++) {
            b.lastReserves[i] = capReserve(
                b.lastReserves[i],
                log2ToUD60x18(reserves[i]),
                blocksPassed
            );
            b.emaReserves[i] = 
                (b.lastReserves[i] * (uUNIT - aN) + b.emaReserves[i] * aN) / uUNIT;
            unchecked { b.cumulativeReserves[i] += b.lastReserves[i] * deltaTimestamp; }
        }

        LibBytes.storeUint128(slot, b.cumulativeReserves);
        assembly { slot := sub(slot, numSlots) }
        LibBytes.storeUint128(slot, b.emaReserves);
        assembly { slot := sub(slot, numSlots) }
        slot.storeLastReserves(uint40(block.timestamp), b.lastReserves);
    }

    function fillLast12Bytes(address addressValue)
        internal
        pure
        returns (bytes32)
    {
        return bytes32(bytes20(addressValue));
    }

    // General Helpers

    function initPump(
        bytes32 slot,
        uint40 lastTimestamp,
        uint[] memory reserves
    ) internal {
        for (uint i = 0; i < reserves.length; i++) {
            reserves[i] = log2ToUD60x18(reserves[i]);
        }
        slot.storeLastReserves(lastTimestamp, reserves);
        uint numSlots = getSlotsOffset(reserves.length);
        assembly { slot := add(slot, numSlots) }
        slot.storeUint128(reserves); // EMA Reserves
    }

    function getSlotsOffset(uint n) internal pure returns (uint) {
        return ((n - 1) / 2 + 1) * 32;
    }

    function getDeltaTimestamp(uint40 lastTimestamp)
        public
        view
        returns (uint)
    {
        return uint(uint40(block.timestamp) - lastTimestamp);
    }

    function log2ToUD60x18(uint x) internal pure returns (uint l) {
        l = unwrap(log2(wrap(x * uUNIT)));
    }

    function exp2FromUD60x18(uint x) internal pure returns (uint y) {
        y = (unwrap(exp2(wrap(x))) - 1e17) / uUNIT + 1;
    }

    /**
     * Last Reserves
     */

    function capReserve(
        uint lastReserve,
        uint reserve,
        uint blocksPassed
    ) internal view returns (uint cappedReserve) {
        if (reserve < lastReserve) {
            uint minReserve = blocksPassed * LOG_MAX_DECREASE;
            minReserve = lastReserve > minReserve ? lastReserve - minReserve : 0;
            if (reserve < minReserve) reserve = minReserve;
        } else {
            uint maxReserve = blocksPassed * LOG_MAX_INCREASE;
            maxReserve = maxReserve < type(uint).max - lastReserve ? 
                lastReserve + maxReserve : 
                type(uint).max;
            if (reserve > maxReserve) reserve = maxReserve;
        }
        cappedReserve = reserve;
    }

    function readLastReserves(address well)
        public
        view
        returns (uint[] memory reserves)
    {
        bytes32 slot = fillLast12Bytes(well);
        (, , reserves) = slot.readLastReserves();
        for (uint i = 0; i < reserves.length; i++) {
            reserves[i] = exp2FromUD60x18(reserves[i]);
        }
    }

    /**
     * EMA Reserves
     */

    function readLastInstantaneousReserves(address well)
        public
        view
        returns (uint[] memory reserves)
    {
        bytes32 slot = fillLast12Bytes(well);
        uint8 n = slot.readN();
        uint offset = getSlotsOffset(n);
        assembly { slot := add(slot, offset) }
        reserves = slot.readUint128(n);
        for (uint i = 0; i < reserves.length; i++) {
            reserves[i] = exp2FromUD60x18(reserves[i]);
        }
    }

    function readInstantaneousReserves(address well)
        public
        view
        returns (uint[] memory reserves)
    {
        bytes32 slot = fillLast12Bytes(well);
        (uint8 n, uint40 lastTimestamp, uint[] memory lastReserves) = slot.readLastReserves();
        uint offset = getSlotsOffset(n);
        assembly { slot := add(slot, offset) }
        reserves = slot.readUint128(n);
        uint deltaTimestamp = getDeltaTimestamp(lastTimestamp);
        uint aN = unwrap(powu(A, deltaTimestamp));
        for (uint i = 0; i < reserves.length; i++) {
            reserves[i] = 
                exp2FromUD60x18((lastReserves[i] * (uUNIT - aN) + reserves[i] * aN) / uUNIT);
        }
    }

    /**
     * Cumulative Reserves
     */

    function readLastCumulativeReserves(address well)
        public
        view
        returns (uint[] memory reserves)
    {
        bytes32 slot = fillLast12Bytes(well);
        uint8 n = slot.readN();
        uint offset = getSlotsOffset(n) * 2;
        assembly {
            slot := add(slot, offset)
        }
        reserves = LibBytes.readUint128(slot, n);
    }

    function readCumulativeReserves(address well)
        public
        view
        returns (uint[] memory cumulativeReserves)
    {
        bytes32 slot = fillLast12Bytes(well);
        (uint8 n, uint40 lastTimestamp, uint[] memory lastReserves) = slot.readLastReserves();
        uint offset = getSlotsOffset(n) * 2;
        assembly { slot := add(slot, offset) }
        cumulativeReserves = slot.readUint128(n);
        uint deltaTimestamp = getDeltaTimestamp(lastTimestamp);
        unchecked {
            for (uint i = 0; i < cumulativeReserves.length; i++) {
                cumulativeReserves[i] += lastReserves[i] * deltaTimestamp;
            }
        }
    }

    function readTwaReserves(
        address well,
        uint[] memory startCumulativeReserves,
        uint startTimestamp
    ) public view returns (uint[] memory twaReserves, uint[] memory cumulativeReserves) {
        cumulativeReserves = readCumulativeReserves(well);
        twaReserves = new uint[](cumulativeReserves.length);
        for (uint i = 0; i < cumulativeReserves.length; i++) {
            // TODO: Unchecked?
            twaReserves[i] = (cumulativeReserves[i] - startCumulativeReserves[i]) / (block.timestamp - startTimestamp);
            twaReserves[i] = exp2FromUD60x18(twaReserves[i]);
        }
    }

    // TODO
    function read(address well, bytes calldata readData)
        external
        view
        returns (bytes memory data)
    {}
}
