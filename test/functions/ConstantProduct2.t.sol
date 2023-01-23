/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";
import {WellFunctionHelper} from "./WellFunctionHelper.sol";
import "src/functions/ConstantProduct2.sol";

/// @dev Tests the {ConstantProduct2} Well function directly.
contract ConstantProduct2Test is WellFunctionHelper {
    /// State A: Same decimals
    uint STATE_A_B0 = 10 * 1e18;
    uint STATE_A_B1 = 10 * 1e18;
    uint STATE_A_LP = 20 * 1e27;

    /// State B: Different decimals
    uint STATE_B_B0 = 1 * 1e18;
    uint STATE_B_B1 = 1250 * 1e6;
    uint STATE_B_LP = 70710678118654752440084;

    /// State C: Similar decimals
    uint STATE_C_B0 = 20 * 1e18;
    uint STATE_C_B1 = 31250000000000000000; // 3.125e19
    uint STATE_C_LP = 50 * 1e27;

    //////////// SETUP ////////////

    function setUp() public {
        _function = new ConstantProduct2();
        _data = "";
    }

    function test_metadata() public {
        assertEq(_function.name(), "Constant Product");
        assertEq(_function.symbol(), "CP");
    }

    //////////// LP TOKEN SUPPLY ////////////

    /// @dev reverts when trying to calculate lp token supply with < 2 balances
    function test_getLpTokenSupply_minBalancesLength() public {
        check_getLpTokenSupply_minBalancesLength(2);
    }

    /// @dev calcLpTokenSupply: same decimals, manual calc for 2 equal balances
    function test_getLpTokenSupply_sameDecimals() public {
        uint[] memory balances = new uint[](2);
        balances[0] = STATE_A_B0;
        balances[1] = STATE_A_B1;
        assertEq(
            _function.calcLpTokenSupply(balances, _data),
            STATE_A_LP // sqrt(10e18 * 10e18) * 2
        );
    }
    
    /// @dev calcLpTokenSupply: diff decimals
    function test_getLpTokenSupply_diffDecimals() public {
        uint[] memory balances = new uint[](2);
        balances[0] = STATE_B_B0; // ex. 1 WETH
        balances[1] = STATE_B_B1; // ex. 1250 BEAN
        assertEq(
            _function.calcLpTokenSupply(balances, _data),
            STATE_B_LP // sqrt(1e18 * 1250e6) * 2
        );
    }

    //////////// BALANCES ////////////

    /// @dev getBalance: same decimals, both positions
    /// Matches example in {testLpTokenSupplySameDecimals}.
    function test_getBalance_sameDecimals() public {
        uint[] memory balances = new uint[](2);

        /// STATE A
        // find balances[0]
        balances[0] = 0;
        balances[1] = STATE_A_B1;
        assertEq(
            _function.calcReserve(balances, 0, STATE_A_LP, _data),
            STATE_A_B0 // (20e18/2) ^ 2 / 10e18 = 10e18
        );

        // find balances[1]
        balances[0] = STATE_A_B0;
        balances[1] = 0;
        assertEq(
            _function.calcReserve(balances, 1, STATE_A_LP, _data),
            STATE_A_B1
        );

        /// STATE C
        // find balances[1]
        balances[0] = STATE_C_B0; 
        balances[1] = 0;
        assertEq(
            _function.calcReserve(balances, 1, STATE_C_LP, _data),
            STATE_C_B1 // (50e18/2) ^ 2 / 20e18 = 31.25e19
        );
    }

    /// @dev getBalance: diff decimals, both positions
    /// Matches example in {testLpTokenSupplyDiffDecimals}.
    function test_getBalance_diffDecimals() public {
        uint[] memory balances = new uint[](2);

        /// STATE B
        // find balances[0]
        balances[0] = 0;
        balances[1] = STATE_B_B1;
        assertEq(
            _function.calcReserve(balances, 0, STATE_B_LP, _data),
            STATE_B_B0 // (70710678118654 / 2)^2 / 1250e6 = ~1e18
        );

        // find balances[1]
        balances[0] = STATE_B_B0; // placeholder
        balances[1] = 0; // ex. 1250 BEAN
        assertEq(
            _function.calcReserve(balances, 1, STATE_B_LP, _data),
            STATE_B_B1 // (70710678118654 / 2)^2 / 1e18 = 1250e6
        );
    }

}