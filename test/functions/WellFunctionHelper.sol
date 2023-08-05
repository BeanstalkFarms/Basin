// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TestHelper, console, stdError} from "test/TestHelper.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";

/// @dev Provides a base test suite for all Well functions.
abstract contract WellFunctionHelper is TestHelper {
    IWellFunction _function;
    bytes _data;

    /// @dev calcLpTokenSupply: 0 reserves = 0 supply
    /// Some Well Functions will choose to support > 2 tokens.
    /// Additional tokens passed in `reserves` should be ignored.
    function test_calcLpTokenSupply_empty(uint256 n) public {
        vm.assume(n < 16);
        vm.assume(n >= 2);
        uint256[] memory reserves = new uint256[](n);
        assertEq(_function.calcLpTokenSupply(reserves, _data), 0);
    }

    /// @dev require at least `n` reserves to be passed to `calcLpTokenSupply`
    function check_calcLpTokenSupply_minBalancesLength(uint256 n) public {
        for (uint256 i; i < n; ++i) {
            vm.expectRevert(stdError.indexOOBError); // "Index out of bounds"
            _function.calcLpTokenSupply(new uint256[](i), _data);
        }
    }
}
