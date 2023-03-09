// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {TestHelper, IERC20, Call, Balances, MockTokenFeeOnTransfer} from "test/TestHelper.sol";
import {ConstantProduct2, IWellFunction} from "src/functions/ConstantProduct2.sol";
import {IWell} from "src/interfaces/IWell.sol";

/**
 * @dev Functions that increase the Well's reserves without accounting for fees
 * (swapFrom, swapTo, addLiquidity) should revert if there actually are fees.
 */
contract WellFeeOnTransferTest is TestHelper {
    event AddLiquidity(uint[] tokenAmountsIn, uint lpAmountOut, address recipient);
    event RemoveLiquidity(uint lpAmountIn, uint[] tokenAmountsOut, address recipient);

    function setUp() public {
        setupWellWithFeeOnTransfer(2);
        MockTokenFeeOnTransfer(address(tokens[0])).setFee(1e16);
    }

    function test_swapTo_feeOnTransfer() public prank(user) {
        uint minAmountOut = 500 * 1e18;
        uint amountIn = 1000 * 1e18;

        vm.expectRevert(IWell.InvalidReserves.selector);
        well.swapTo(tokens[0], tokens[1], amountIn, minAmountOut, user, type(uint).max);
    }

    function test_swapFrom_feeOnTransfer() public prank(user) {
        uint minAmountOut = 500 * 1e18;
        uint amountIn = 1000 * 1e18;

        vm.expectRevert(IWell.InvalidReserves.selector);
        well.swapFrom(tokens[0], tokens[1], amountIn, minAmountOut, user, type(uint).max);
    }

    function test_addLiquidity_feeOnTransfer() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);

        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }
        uint lpAmountOut = 1000 * 1e24;

        vm.expectRevert(IWell.InvalidReserves.selector);
        well.addLiquidity(amounts, lpAmountOut, user, type(uint).max);
    }
}
