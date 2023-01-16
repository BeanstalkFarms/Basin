/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";

contract SwapTest is TestHelper {

    event AddLiquidity(uint[] amounts);

    event Swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint fromAmount,
        uint toAmount
    );

    function setUp() public {
        setupWell(2);
    }

    //////////// SWAP: OUT ////////////

    function testGetSwapOut() public {
        uint amountIn = 1000 * 1e18;
        uint amountOut = well.getSwapOut(tokens[0], tokens[1], amountIn);
        assertEq(amountOut, 500 * 1e18);
    }

    function testSwapOut() prank(user) public {
        uint amountIn = 1000 * 1e18;
        uint minAmountOut = 500 * 1e18;

        uint balanceBefore0 = tokens[0].balanceOf(user);
        uint balanceBefore1 = tokens[1].balanceOf(user);

        vm.expectEmit(true, true, true, true);
        emit Swap(tokens[0], tokens[1], amountIn, minAmountOut);

        uint amountOut = well.swapFrom(tokens[0], tokens[1], amountIn, minAmountOut, user);

        assertEq(balanceBefore0 - tokens[0].balanceOf(user), amountIn);
        assertEq(tokens[1].balanceOf(user) - balanceBefore1, amountOut);

        assertEq(tokens[0].balanceOf(address(well)), 2000 * 1e18);
        assertEq(tokens[1].balanceOf(address(well)), 500 * 1e18);
    }

    function testSwapOutMinTooHigh() prank(user) public {
        uint amountIn = 1000 * 1e18;
        vm.expectRevert("Well: slippage");
        well.swapFrom(tokens[0], tokens[1], amountIn, 501 * 1e18, user);
    }

    //////////// SWAP: IN ////////////

    function testGetSwapIn() public {
        uint amountOut = 500 * 1e18;
        uint amountIn = well.getSwapIn(tokens[0], tokens[1], amountOut);
        assertEq(amountIn, 1000 * 1e18);
    }

    function testSwapIn() prank(user) public {
        uint amountOut = 500 * 1e18;
        uint maxAmountIn = 1000 * 1e18;

        vm.expectEmit(true, true, true, true);
        emit Swap(tokens[0], tokens[1], maxAmountIn, amountOut);

        uint balanceBefore0 = tokens[0].balanceOf(user);
        uint balanceBefore1 = tokens[1].balanceOf(user);

        uint amountIn = well.swapTo(tokens[0], tokens[1], maxAmountIn, amountOut, user);

        assertEq(balanceBefore0 - tokens[0].balanceOf(user), amountIn);
        assertEq(tokens[1].balanceOf(user) - balanceBefore1, amountOut);

        assertEq(tokens[0].balanceOf(address(well)), 2000 * 1e18);
        assertEq(tokens[1].balanceOf(address(well)), 500 * 1e18);
    }

    function testSwapOutMaxTooLow() prank(user) public {
        uint amountOut = 500 * 1e18;
        vm.expectRevert("Well: slippage");
        well.swapTo(tokens[0], tokens[1], 999 * 1e18, amountOut, user);
    }
}
