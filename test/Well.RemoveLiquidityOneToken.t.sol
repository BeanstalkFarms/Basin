/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";


contract RemoveLiquidityOneTokenTest is TestHelper {
    ConstantProduct2 cp;

    event RemoveLiquidityOneToken(
        uint lpAmountIn,
        IERC20 tokenOut,
        uint tokenAmountOut
    );

    function setUp() public {
        setupWell(2);
        addLiquidityEqualAmount(user, 1000 * 1e18);
    }

    function testGetRemoveLiquidityOneTokenOut() public {
        uint amountOut = well.getRemoveLiquidityOneTokenOut(tokens[0], 1000 * 1e27);
        assertEq(amountOut, 875 * 1e18, "incorrect tokenOut");
    }

    function testRemoveLiquidityOneToken() prank(user) public {
        uint lpAmountIn = 1000 * 1e27;
        uint minTokenAmountOut = 875 * 1e18;

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidityOneToken(lpAmountIn, tokens[0], minTokenAmountOut);

        uint amountOut = well.removeLiquidityOneToken(lpAmountIn, tokens[0], minTokenAmountOut, user);

        assertEq(well.balanceOf(user), lpAmountIn, "incorrect lpAmountIn");

        assertEq(tokens[0].balanceOf(user), amountOut, "incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user), 0, "incorrect token1 user amt");

        assertEq(tokens[0].balanceOf(address(well)), 1125 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 2000 * 1e18, "incorrect token1 well amt");
    }

    function testRemoveLiquidityOneTokenAmountOutTooHigh() prank(user) public {
        uint lpAmountIn = 1000 * 1e18;
        uint minTokenAmountOut = 876 * 1e18;

        vm.expectRevert("Well: slippage");
        well.removeLiquidityOneToken(lpAmountIn, tokens[0], minTokenAmountOut, user);
    }

    function testRemoveLiqudityImbalancedFuzz(uint x) prank(user) public {
        uint[] memory amounts = new uint[](2);
        // limit remoove liquidity to account for slippage
        amounts[0] = bound(x,0,750e18); 
        amounts[1] = 0;

        uint userLPBalance = well.balanceOf(user);
        cp = new ConstantProduct2();
        bytes memory data = "";
        uint[] memory balances = new uint[](2);
        uint lpAmountIn = well.getRemoveLiquidityImbalancedIn(amounts);
        console.log("lpAmountIn",lpAmountIn);
        balances[0] = tokens[0].balanceOf(address(well)) - amounts[0];
        balances[1] = tokens[1].balanceOf(address(well)) - amounts[1];

        uint newLpTokenSupply =  cp.getLpTokenSupply(balances,data);
        console.log("NewTknSupply", newLpTokenSupply);
        uint totalSupply = well.totalSupply();
        console.log("TotalSupply",totalSupply);
        uint amountOut = totalSupply - newLpTokenSupply;
        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidityOneToken(amountOut,tokens[0],amounts[0]);

        well.removeLiquidityOneToken(amountOut,tokens[0],0,user);

        assertEq(well.balanceOf(user), userLPBalance - lpAmountIn, "Incorrect lp output");

        assertEq(tokens[0].balanceOf(user), amounts[0], "Incorrect token0 user balance");
        assertEq(tokens[1].balanceOf(user), amounts[1], "Incorrect token1 user balance");
        assertEq(tokens[0].balanceOf(address(well)), 2000e18 - amounts[0], "Incorrect token0 well balance");
        assertEq(tokens[1].balanceOf(address(well)), 2000e18 - amounts[1], "Incorrect token1 well balance");
        
    }
}
