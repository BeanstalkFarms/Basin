/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";
import "src/functions/ConstantProduct2.sol";

contract ConstantProduct2Test is TestHelper {
    ConstantProduct2 _function;
    bytes data = "";

    function setUp() public {
        _function = new ConstantProduct2();
    }

    function testName() public {
        assertEq(_function.name(), "Constant Product");
        assertEq(_function.symbol(), "CP");
    }

    //////////// LP TOKEN SUPPLY ////////////

    /// @dev getLpTokenSupply: Should revert if balances.length < 2
    function testLpTokenRevertBalancesLength() public {
        vm.expectRevert();
        _function.getLpTokenSupply(data, new uint[](0));
        vm.expectRevert();
        _function.getLpTokenSupply(data, new uint[](1));
    }

    /// @dev getLpTokenSupply: 0 balances = 0 supply
    function testLpTokenSupplyEmpty() public {
        uint[] memory balances = new uint[](2);
        balances[0] = 0;
        balances[1] = 0;
        assertEq(_function.getLpTokenSupply(data, balances), 0);
    }

    /// @dev getLpTokenSupply: same decimals, manual calc for 2 equal balances
    function testLpTokenSupplySameDecimals() public {
        uint[] memory balances = new uint[](2);
        balances[0] = 10 * 1e18;
        balances[1] = 10 * 1e18;
        assertEq(
            _function.getLpTokenSupply(data, balances),
            20 * 1e18 // sqrt(10e18 * 10e18) * 2
        );
    }
    
    /// @dev getLpTokenSupply: diff decimals
    function testLpTokenSupplyDiffDecimals() public {
        uint[] memory balances = new uint[](2);
        balances[0] = 1 * 1e18; // ex. 1 WETH
        balances[1] = 1250 * 1e6; // ex. 1250 BEAN
        assertEq(
            _function.getLpTokenSupply(data, balances),
            70710678118654 // sqrt(1e18 * 1250e6) * 2
        );
    }

    //////////// BALANCES ////////////

    /// @dev getBalance: same decimals, both positions
    function testBalanceSameDecimals() public {
        uint[] memory balances = new uint[](2);
        uint lpTokenSupply;

        // find balances[0] (matches {testLpTokenSupplySameDecimals})
        lpTokenSupply = 20 * 1e18;
        balances[0] = 0; // placeholder
        balances[1] = 10 * 1e18;
        assertEq(
            _function.getBalance(data, balances, 0, lpTokenSupply),
            10 * 1e18 // (20e18/2) ^ 2 / 10e18 = 10e18
        );

        // find balances[1]
        lpTokenSupply = 50 * 1e18;
        balances[0] = 20 * 1e18; 
        balances[1] = 0; // placeholder
        assertEq(
            _function.getBalance(data, balances, 1, lpTokenSupply),
            31250000000000000000 // (50e18/2) ^ 2 / 20e18 = 31.25e19
        );
    }

    /// @dev getBalance: diff decimals, both positions
    /// matches example in testLpTokenSupplyDiffDecimals()
    function testBalanceDiffDecimals() public {
        uint[] memory balances = new uint[](2);
        uint lpTokenSupply  = 70710678118654;

        // find balances[0]
        balances[0] = 0; // placeholder
        balances[1] = 1250 * 1e6; // ex. 1250 BEAN
        assertEq(
            _function.getBalance(data, balances, 0, lpTokenSupply),
            1 * 1e18 // (70710678118654 / 2)^2 / 1250e6 = ~1e18
        );

        // find balances[1]
        balances[0] = 1 * 1e18; // placeholder
        balances[1] = 0; // ex. 1250 BEAN
        assertEq(
            _function.getBalance(data, balances, 1, lpTokenSupply),
            1250e6 // (70710678118654 / 2)^2 / 1e18 = 1250e6
        );
    }

}