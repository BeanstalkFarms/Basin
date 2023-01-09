/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";

contract RemoveLiquidityImbalancedTest is TestHelper {
    uint[] tokenAmountsOut;

    event RemoveLiquidity(uint lpAmountIn, uint[] tokenAmountsOut);

    function setUp() public {
        setupWell(2);
        addLiquidtyEqualAmount(user, 1000 * 1e18);

        tokenAmountsOut.push(500 * 1e18);
        tokenAmountsOut.push(506 * 1e17);
    }

    function testGetRemoveLiquidityImbalancedOut() public {

        uint lpAmountIn = well.getRemoveLiquidityImbalanced(tokenAmountsOut);
        assertEq(lpAmountIn, 580 * 1e18);
    }

    function testRemoveLiquidityImbalanced() prank(user) public {
        uint maxLPAmountIn = 580 * 1e18;

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(maxLPAmountIn, tokenAmountsOut);

        well.removeLiquidityImbalanced(maxLPAmountIn, tokenAmountsOut, user);

        assertEq(well.balanceOf(user), (2000 - 580) * 1e18);

        assertEq(tokens[0].balanceOf(user), tokenAmountsOut[0]);
        assertEq(tokens[1].balanceOf(user), tokenAmountsOut[1]);

        assertEq(tokens[0].balanceOf(address(well)), 1500 * 1e18);
        assertEq(tokens[1].balanceOf(address(well)), 19494 * 1e17);
    }

    function testRemoveLiquidityImbalancedAmountOutTooHigh() prank(user) public {
        uint maxLPAmountIn = 579 * 1e18;

        vm.expectRevert("Well: slippage");
        well.removeLiquidityImbalanced(maxLPAmountIn, tokenAmountsOut, user);

    }
}
