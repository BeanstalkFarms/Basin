// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {console, TestHelper, IERC20, Call, Balances, MockTokenFeeOnTransfer} from "test/TestHelper.sol";
import {ConstantProduct2, IWellFunction} from "src/functions/ConstantProduct2.sol";

contract WellFeeOnTransferTest is TestHelper {
    event AddLiquidity(uint[] tokenAmountsIn, uint lpAmountOut);
    event RemoveLiquidity(uint lpAmountIn, uint[] tokenAmountsOut);

    function setUp() public {
        deployMockTokensFeeOnTransfer(2);
        setupWell(0);
        MockTokenFeeOnTransfer(address(tokens[0])).setFee(1e16);
    }

    function test_swapTo_feeOnTransfer() public prank(user) {
        uint amountOut = 500 * 1e18;
        uint maxAmountIn = 1000 * 1e18;

        vm.expectRevert("Well: Invalid reserve");
        uint amountIn = well.swapTo(tokens[0], tokens[1], maxAmountIn, amountOut, user);
    }

    function test_swapFrom_feeOnTransfer() public prank(user) {
        uint amountOut = 500 * 1e18;
        uint maxAmountIn = 1000 * 1e18;

        vm.expectRevert("Well: Invalid reserve");
        uint amountIn = well.swapFrom(tokens[0], tokens[1], maxAmountIn, amountOut, user);
    }

    function test_addLiquidity_feeOnTransfer() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);

        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }
        uint lpAmountOut = 2000 * 1e27;

        vm.expectRevert("Well: Invalid reserve");
        well.addLiquidity(amounts, lpAmountOut, user);
    }
}
