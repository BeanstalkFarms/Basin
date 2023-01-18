/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "src/interfaces/IPump.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";
import "oz/utils/math/SafeCast.sol";
import {log2 as slog2, wrap as swrap, unwrap as sunwrap} from "prb/math/SD59x18.sol";

/**
 * @author Publius
 * @title Beanstalk Pump intended for use in Beanstalk.
 * @dev
 * A Pump designed for use in Beanstalk with 2 tokens.
 * This Pump has 3 main features:
 * 1. Multi-block MEV resistence balances
 * 2. MEV-resistant Geometric EMA intended for instantaneous balance queries
 * 3. MEV-resistant Cumulative Geometric intended for SMA balance queries
 **/
contract BeanstalkPump2 is IPump {
    using SafeCast for uint;

    uint immutable LOG_MAX_INCREASE;
    uint immutable LOG_MAX_DECREASE;
    uint immutable BLOCK_TIME;
    UD60x18 immutable A;

    struct Balances {
        uint128 lastBalance0;
        uint128 lastBalance1;
        uint48 lastTimestamp;
        uint104 lastEmaBalance0; // type(uint104).max > 2e31 > 192e18 (log2ToUD60x18 returns a max of 192e18). uint104 is safe
        uint104 lastEmaBalance1;
        uint128 lastCumulativeBalance0; // type(uint128).max > 3.4e38 > 5.5e34 > 192e18 * 2^48 (log2ToUD60x18 returns a max of 192e18). uint128 is safe.
        uint128 lastCumulativeBalance1;
    }

    mapping(address => Balances) pumpBalances;

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
        LOG_MAX_DECREASE = uint(-sunwrap(slog2(swrap((uUNIT - _maxPercentChange).toInt256()))));
        BLOCK_TIME = _blockTime;
        A = wrap(_A);
    }

    function attach(uint _n, bytes calldata pumpData) external {}

    function update(uint[] calldata balances, bytes calldata)
        external
    {
        Balances memory b = pumpBalances[msg.sender];
        uint deltaTimestamp = getDeltaTimestamp(b.lastTimestamp);

        // TODO: Finalize init condition. timestamp? lastBalance?
        if (b.lastBalance0 == 0) {
            initPump(uint48(block.timestamp), balances, b);
            return;
        }

        b.lastTimestamp = uint48(block.timestamp);

        (b.lastBalance0, b.lastBalance1) = updateLastBalances(
            deltaTimestamp,
            b.lastBalance0,
            b.lastBalance1,
            balances[0],
            balances[1]
        );

        (b.lastEmaBalance0, b.lastEmaBalance1) = updateEmaBalances(
            deltaTimestamp,
            b
        );

        (
            b.lastCumulativeBalance0,
            b.lastCumulativeBalance1
        ) = updateCumulativeBalances(deltaTimestamp, b);

        pumpBalances[msg.sender] = b;
    }

    // General Helpers

    function initPump(uint48 lastTimestamp, uint[] memory balances, Balances memory b) internal {
        b.lastTimestamp = lastTimestamp;
        b.lastBalance0 = log2ToUD60x18(balances[0]).toUint128();
        b.lastBalance1 = log2ToUD60x18(balances[1]).toUint128();
        b.lastEmaBalance0 = uint(b.lastBalance0).toUint104();
        b.lastEmaBalance1 = uint(b.lastBalance1).toUint104();
        pumpBalances[msg.sender] = b;
    }

    function getDeltaTimestamp(uint48 lastTimestamp)
        public
        view
        returns (uint)
    {
        return uint(uint48(block.timestamp) - lastTimestamp);
    }

    function log2ToUD60x18(uint x) internal pure returns (uint l) {
        l = unwrap(log2(wrap(x * uUNIT)));
    }

    function exp2FromUD60x18(uint x)
        internal
        pure
        returns (uint y)
    {
        y = (unwrap(exp2(wrap(x))) - 1e17) / uUNIT + 1;
    }

    function convertBalancesFromLog(uint balance0, uint balance1)
        internal
        pure
        returns (uint[] memory balances)
    {
        balances = new uint[](2);
        balances[0] = exp2FromUD60x18(balance0);
        balances[1] = exp2FromUD60x18(balance1);
    }

    /**
     * Last Balances
     */

    function updateLastBalances(
        uint deltaTimestamp,
        uint lastBalance0,
        uint lastBalance1,
        uint balance0,
        uint balance1
    ) internal view returns (uint128 cappedBalance0, uint128 cappedBalance1) {
        uint blocksPassed = deltaTimestamp / BLOCK_TIME;
        cappedBalance0 = capBalance(lastBalance0, balance0, blocksPassed).toUint128();
        cappedBalance1 = capBalance(lastBalance1, balance1, blocksPassed).toUint128();
    }

    function capBalance(
        uint lastBalance,
        uint balance,
        uint blocksPassed
    ) internal view returns (uint cappedBalance) {
        balance = log2ToUD60x18(balance);
        if (balance < lastBalance) {
            uint minBalance = lastBalance - blocksPassed * LOG_MAX_DECREASE;
            if (balance < minBalance) balance = minBalance;
        } else {
            uint maxBalance = lastBalance + blocksPassed * LOG_MAX_INCREASE;
            if (balance > maxBalance) balance = maxBalance;
        }
        cappedBalance = balance;
    }

    function readLastBalances(address well)
        public
        view
        returns (uint[] memory balances)
    {
        Balances memory b = pumpBalances[well];
        balances = convertBalancesFromLog(b.lastBalance0, b.lastBalance1);
    }

    /**
     * EMA Balances
     */

    function readLastEmaBalances(address well)
        public
        view
        returns (uint[] memory balances)
    {
        Balances memory b = pumpBalances[well];
        balances = convertBalancesFromLog(b.lastEmaBalance0, b.lastEmaBalance1);
    }

    function readCurrentEmaBalances(address well)
        public
        view
        returns (uint[] memory balances)
    {
        Balances memory b = pumpBalances[well];
        uint deltaTimestamp = getDeltaTimestamp(b.lastTimestamp);
        (
            uint currentEmaBalance0,
            uint currentEmaBalance1
        ) = updateEmaBalances(deltaTimestamp, b);
        balances = convertBalancesFromLog(
            currentEmaBalance0,
            currentEmaBalance1
        );
    }

    function updateEmaBalances(uint deltaTimestamp, Balances memory b)
        internal
        view
        returns (uint104 emaBalance0, uint104 emaBalance1)
    {
        uint aN = unwrap(powu(A, deltaTimestamp));
        emaBalance0 = ((b.lastBalance0 * (uUNIT - aN) + b.lastEmaBalance0 * aN) /
            uUNIT).toUint104();
        emaBalance1 = ((b.lastBalance1 * (uUNIT - aN) + b.lastEmaBalance1 * aN) /
            uUNIT).toUint104();
    }

    /**
     * Cumulative Balances
     */

    function readLastCumulativeBalances(address well)
        public
        view
        returns (uint128[] memory balances)
    {
        Balances memory b = pumpBalances[well];
        balances = new uint128[](2);
        balances[0] = b.lastCumulativeBalance0;
        balances[1] = b.lastCumulativeBalance1;
    }

    function readCurrentCumulativeBalances(address well)
        public
        view
        returns (uint128[] memory balances)
    {
        Balances memory b = pumpBalances[well];
        uint deltaTimestamp = uint(
            uint48(block.timestamp) - b.lastTimestamp
        );
        balances = new uint128[](2);
        (balances[0], balances[1]) = updateCumulativeBalances(
            deltaTimestamp,
            b
        );
    }

    function updateCumulativeBalances(uint deltaTimestamp, Balances memory b)
        internal
        pure
        returns (uint128 cumulativeBalance0, uint128 cumulativeBalance1)
    {
        unchecked {
            cumulativeBalance0 = (b.lastCumulativeBalance0 +
                b.lastBalance0 * deltaTimestamp).toUint128();
            cumulativeBalance1 = (b.lastCumulativeBalance1 +
                b.lastBalance1 * deltaTimestamp).toUint128();
        }
    }

    function read(address well, bytes calldata readData)
        external
        view
        returns (bytes memory data)
    {
        // if (readData[0] == 0) {
        //     data = abi.encode(readEmaBalances(well));
        // } else if (readData[0] == 1) {
        //     balances = readCumulativeBalances(well, abi.decode(data[1:], (uint[])), abi.decode(data[33:], (uint48)));
        // }
    }

    function readAllBalances(address well)
        external
        view
        returns (Balances memory pb)
    {
        pb = pumpBalances[well];
    }
}
