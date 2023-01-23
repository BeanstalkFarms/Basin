/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import {TestHelper, console, stdError} from "test/TestHelper.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";

/// @dev Provides a base test suite for all Well functions.
abstract contract WellFunctionHelper is TestHelper {
    IWellFunction _function;
    bytes _data;

    /// @dev calcLpTokenSupply: 0 balances = 0 supply
    /// Some Well Functions will choose to support > 2 tokens.
    /// Additional tokens passed in `balances` should be ignored.
    function test_getLpTokenSupply_empty(uint n) public {
        vm.assume(n < 16);
        vm.assume(n >= 2);
        uint[] memory balances = new uint[](n);
        assertEq(_function.calcLpTokenSupply(balances, _data), 0);
    }

    /// @dev require at least `n` balances to be passed to `calcLpTokenSupply`
    function check_getLpTokenSupply_minBalancesLength(uint n) public {
        for (uint i = 0; i < n; ++i) {
            vm.expectRevert(stdError.indexOOBError); // "Index out of bounds"
            _function.calcLpTokenSupply(new uint[](i), _data);
        }
    }
}