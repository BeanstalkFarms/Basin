// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {TestHelper, IERC20, Call, Balances, MockTokenFeeOnTransfer} from "test/TestHelper.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";
import {IWell} from "src/interfaces/IWell.sol";
import {IWellErrors} from "src/interfaces/IWellErrors.sol";

/**
 * @dev Functions that increase the Well's reserves without accounting for fees
 * (swapFrom, swapTo, addLiquidity) should revert if there actually are fees.
 */
contract WellFeeOnTransferTest is TestHelper {
    event AddLiquidity(uint256[] tokenAmountsIn, uint256 lpAmountOut, address recipient);
    event RemoveLiquidity(uint256 lpAmountIn, uint256[] tokenAmountsOut, address recipient);

    function setUp() public {
        setupWellWithFeeOnTransfer(2);
        MockTokenFeeOnTransfer(address(tokens[0])).setFee(1e16);
    }

    function test_swapTo_feeOnTransfer() public prank(user) {
        uint256 minAmountOut = 500 * 1e18;
        uint256 amountIn = 1000 * 1e18;

        vm.expectRevert(IWellErrors.InvalidReserves.selector);
        well.swapTo(tokens[0], tokens[1], amountIn, minAmountOut, user, type(uint256).max);
    }

    function test_swapFrom_feeOnTransfer() public prank(user) {
        uint256 minAmountOut = 500 * 1e18;
        uint256 amountIn = 1000 * 1e18;

        vm.expectRevert(IWellErrors.InvalidReserves.selector);
        well.swapFrom(tokens[0], tokens[1], amountIn, minAmountOut, user, type(uint256).max);
    }

    function test_addLiquidity_feeOnTransfer() public prank(user) {
        uint256[] memory amounts = new uint256[](tokens.length);

        for (uint256 i; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }
        uint256 lpAmountOut = 1000 * 1e24;

        vm.expectRevert(IWellErrors.InvalidReserves.selector);
        well.addLiquidity(amounts, lpAmountOut, user, type(uint256).max);
    }
}
