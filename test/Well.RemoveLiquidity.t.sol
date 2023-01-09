/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";

contract RemoveLiquidityTest is TestHelper {

    event RemoveLiquidity(uint lpAmountIn, uint[] tokenAmountsOut);

    function setUp() public {
        setupWell(2);
        addLiquidtyEqualAmount(user, 1000 * 1e18);
    }

    function testGetRemoveLiquidityOut() public {
        uint[] memory amountsOut = well.getRemoveLiquidityOut(2000 * 1e18);
        for (uint i = 0; i < tokens.length; i++) assertEq(amountsOut[i], 1000 * 1e18);
    }

    function testRemoveLiquidity() prank(user) public {
        uint lpAmountIn = 2000 * 1e18;
        uint[] memory amountsOut = new uint[](2);
        amountsOut[0] = 1000 * 1e18;
        amountsOut[1] = 1000 * 1e18;

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(lpAmountIn, amountsOut);

        well.removeLiquidity(lpAmountIn, amountsOut, user);

        assertEq(well.balanceOf(user), 0);

        assertEq(tokens[0].balanceOf(user), amountsOut[0]);
        assertEq(tokens[1].balanceOf(user), amountsOut[1]);

        assertEq(tokens[0].balanceOf(address(well)), 1000 * 1e18);
        assertEq(tokens[1].balanceOf(address(well)), 1000 * 1e18);
    }

    function testRemoveLiquidityAmountOutTooHigh() prank(user) public {
        uint lpAmountIn = 2000 * 1e18;
        uint[] memory amountsOut = new uint[](2);
        amountsOut[0] = 1001 * 1e18;
        amountsOut[1] = 1000 * 1e18;

        vm.expectRevert("Well: slippage");
        well.removeLiquidity(lpAmountIn, amountsOut, user);
    }
}
