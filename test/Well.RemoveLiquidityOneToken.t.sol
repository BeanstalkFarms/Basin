/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";

contract RemoveLiquidityOneTokenTest is TestHelper {

    event RemoveLiquidityOneToken(
        uint lpAmountIn,
        IERC20 tokenOut,
        uint tokenAmountOut
    );

    function setUp() public {
        setupWell(2);
        addLiquidtyEqualAmount(user, 1000 * 1e18);
    }

    function testGetRemoveLiquidityOneTokenOut() public {
        uint amountOut = well.getRemoveLiquidityOneTokenOut(tokens[0], 1000 * 1e18);
        assertEq(amountOut, 875 * 1e18);
    }

    function testRemoveLiquidityOneToken() prank(user) public {
        uint lpAmountIn = 1000 * 1e18;
        uint minTokenAmountOut = 875 * 1e18;

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidityOneToken(lpAmountIn, tokens[0], minTokenAmountOut);

        uint amountOut = well.removeLiquidityOneToken(lpAmountIn, tokens[0], minTokenAmountOut, user);

        assertEq(well.balanceOf(user), 1000 * 1e18);

        assertEq(tokens[0].balanceOf(user), amountOut);
        assertEq(tokens[1].balanceOf(user), 0);

        assertEq(tokens[0].balanceOf(address(well)), 1125 * 1e18);
        assertEq(tokens[1].balanceOf(address(well)), 2000 * 1e18);
    }

    function testRemoveLiquidityOneTokenAmountOutTooHigh() prank(user) public {
        uint lpAmountIn = 1000 * 1e18;
        uint minTokenAmountOut = 876 * 1e18;

        vm.expectRevert("Well: slippage");
        well.removeLiquidityOneToken(lpAmountIn, tokens[0], minTokenAmountOut, user);
    }
}
