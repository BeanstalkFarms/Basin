/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";

contract RemoveLiquidityTest is TestHelper {
    ConstantProduct2 cp;

    event RemoveLiquidity(uint lpAmountIn, uint[] tokenAmountsOut);

    function setUp() public {
        setupWell(2);
        addLiquidityEqualAmount(user, 1000 * 1e18);
    }

    function testGetRemoveLiquidityOut() public {
        uint[] memory amountsOut = well.getRemoveLiquidityOut(2000 * 1e27);
        for (uint i = 0; i < tokens.length; i++) 
            assertEq(amountsOut[i], 1000 * 1e18, "incorrect getRemoveLiquidityOut");
    }

    function testRemoveLiquidity() prank(user) public {
        uint lpAmountIn = 2000 * 1e27;
        uint[] memory amountsOut = new uint[](2);
        amountsOut[0] = 1000 * 1e18;
        amountsOut[1] = 1000 * 1e18;

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(lpAmountIn, amountsOut);

        well.removeLiquidity(lpAmountIn, amountsOut, user);

        assertEq(well.balanceOf(user), 0);

        assertEq(tokens[0].balanceOf(user), amountsOut[0], "incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user), amountsOut[1], "incorrect token1 user amt");

        assertEq(tokens[0].balanceOf(address(well)), 1000 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 1000 * 1e18, "incorrect token1 well amt");
    }

    function testRemoveLiquidityAmountOutTooHigh() prank(user) public {
        uint lpAmountIn = 2000 * 1e18;
        uint[] memory amountsOut = new uint[](2);
        amountsOut[0] = 1001 * 1e18;
        amountsOut[1] = 1000 * 1e18;

        vm.expectRevert("Well: slippage");
        well.removeLiquidity(lpAmountIn, amountsOut, user);
    }

    function testRemoveLiqudityFuzz(uint x) prank(user) public {
        uint[] memory amounts = new uint[](2);

        // limit remoove liquidity to account for slippage
        amounts[0] = bound(x, 0, 750e18); 
        amounts[1] = amounts[0];

        uint userLPBalance = well.balanceOf(user);
        cp = new ConstantProduct2();
        bytes memory data = "";
        uint[] memory balances = new uint[](2);
        uint lpAmountIn = well.getRemoveLiquidityImbalancedIn(amounts);
        console.log("lpAmountIn", lpAmountIn);
        balances[0] = tokens[0].balanceOf(address(well)) - amounts[0];
        balances[1] = tokens[1].balanceOf(address(well)) - amounts[1];

        uint newLpTokenSupply =  cp.getLpTokenSupply(balances,data);
        console.log("NewTknSupply", newLpTokenSupply);
        uint totalSupply = well.totalSupply();
        console.log("TotalSupply",totalSupply);
        uint amountOut = totalSupply - newLpTokenSupply;
        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(amountOut,amounts);
        uint[] memory minAmt = new uint[](2);
        well.removeLiquidity(amountOut,minAmt,user);

        assertEq(well.balanceOf(user), userLPBalance - lpAmountIn, "Incorrect lp output");

        assertEq(tokens[0].balanceOf(user), amounts[0], "Incorrect token0 user balance");
        assertEq(tokens[1].balanceOf(user), amounts[1], "Incorrect token1 user balance");
        assertEq(tokens[0].balanceOf(address(well)), 2000e18 - amounts[0], "Incorrect token0 well balance");
        assertEq(tokens[1].balanceOf(address(well)), 2000e18 - amounts[1], "Incorrect token1 well balance");

    }
}
