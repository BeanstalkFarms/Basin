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

        assertEq(balanceBefore0 - tokens[0].balanceOf(user), amountIn, "incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user) - balanceBefore1, amountOut, "incorrect token1 user amt");

        assertEq(tokens[0].balanceOf(address(well)), 2000 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 500 * 1e18, "incorrect token0 well amt");
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

        assertEq(balanceBefore0 - tokens[0].balanceOf(user), amountIn, "incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user) - balanceBefore1, amountOut, "incorrect token1 user amt");

        assertEq(tokens[0].balanceOf(address(well)), 2000 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 500 * 1e18, "incorrect token1 well amt");
    }

    function testSwapOutMaxTooLow() prank(user) public {
        uint amountOut = 500 * 1e18;
        vm.expectRevert("Well: slippage");
        well.swapTo(tokens[0], tokens[1], 999 * 1e18, amountOut, user);
    }

    function testSwapInFuzz() prank(user) public {
        uint amountOut = 500 * 1e18;
        uint maxAmountIn = 1000 * 1e18;

        vm.expectEmit(true, true, true, true);
        emit Swap(tokens[0], tokens[1], maxAmountIn, amountOut);

        uint balanceBefore0 = tokens[0].balanceOf(user);
        uint balanceBefore1 = tokens[1].balanceOf(user);

        uint amountIn = well.swapTo(tokens[0], tokens[1], maxAmountIn, amountOut, user);

        assertEq(balanceBefore0 - tokens[0].balanceOf(user), amountIn, "incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user) - balanceBefore1, amountOut, "incorrect token1 user amt");

        assertEq(tokens[0].balanceOf(address(well)), 2000 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 500 * 1e18, "incorrect token1 well amt");
    }

    function testSwapOutFuzz(uint amountIn) prank(user) public {
        amountIn =bound(amountIn,0,1000 * 1e18); 
        uint balanceBefore0 = tokens[0].balanceOf(user);
        uint balanceBefore1 = tokens[1].balanceOf(user);
        uint[] memory wellBalances = new uint[](2);
        wellBalances[0] = tokens[0].balanceOf(address(well));
        wellBalances[1] = tokens[1].balanceOf(address(well));

        uint calcAmountOut = uint256(well.calculateSwap(wellBalances,0,1,int(amountIn)));

        vm.expectEmit(true, true, true, true);
        emit Swap(tokens[0], tokens[1], amountIn, calcAmountOut);

        uint amountOut = well.swapFrom(tokens[0], tokens[1], amountIn, 0, user);

        assertEq(amountOut,calcAmountOut,"actual vs expected output");
        assertEq(balanceBefore0 - tokens[0].balanceOf(user), amountIn, "input amt for swap");
        assertEq(tokens[1].balanceOf(user) - balanceBefore1, calcAmountOut, "output amt for swap");

        assertEq(tokens[0].balanceOf(address(well)), wellBalances[0] + amountIn, "token0 well balance");
        assertEq(tokens[1].balanceOf(address(well)), wellBalances[1] - calcAmountOut, "token1 well balance");
    }
}
