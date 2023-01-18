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

    /// @dev liquidity is initially added in {TestHelper} and {setUp} above.
    /// this will ensure that subsequent tests run correctly.
    function testLiquidityInitialized() public {
        IERC20[] memory tokens = well.tokens();
        for(uint i = 0; i < tokens.length; i++) {
            assertEq(tokens[i].balanceOf(address(well)), 2000 * 1e18, "incorrect token balance");
        }
        assertEq(well.totalSupply(), 2000 * 1e17, "incorrect totalSupply");
    }

    /// @dev getRemoveLiquidityOut: remove to equal amounts of underlying
    /// since the tokens in the Well are balanced, user receives equal amounts
    function testGetRemoveLiquidityOut() public {
        uint[] memory amountsOut = well.getRemoveLiquidityOut(2000 * 1e27);
        for (uint i = 0; i < tokens.length; i++) 
            assertEq(amountsOut[i], 1000 * 1e18, "incorrect getRemoveLiquidityOut");
    }

    /// @dev removeLiquidity: remove to equal amounts of underlying
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

    /// @dev removeLiquidity: reverts when user requests too much of an underlying token
    function testRemoveLiquidityAmountOutTooHigh() prank(user) public {
        uint lpAmountIn = 2000 * 1e18;
        uint[] memory amountsOut = new uint[](2);
        amountsOut[0] = 1001 * 1e18;
        amountsOut[1] = 1000 * 1e18;

        vm.expectRevert("Well: slippage");
        well.removeLiquidity(lpAmountIn, amountsOut, user);
    }

    function testRemoveLiqudityFuzz(uint tknRemoved) prank(user) public {
        uint[] memory amounts = new uint[](2);


        amounts[0] = bound(tknRemoved, 0, 1000e18); 
        amounts[1] = amounts[0];

        uint userLPBalance = well.balanceOf(user);
        cp = new ConstantProduct2();
        bytes memory data = "";
        uint[] memory balances = new uint[](2);
        uint lpAmountIn = well.getRemoveLiquidityImbalancedIn(amounts);
        balances[0] = tokens[0].balanceOf(address(well)) - amounts[0];
        balances[1] = tokens[1].balanceOf(address(well)) - amounts[1];

        uint newLpTokenSupply =  cp.getLpTokenSupply(balances,data);
        uint totalSupply = well.totalSupply();
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

    function testRemoveLiqudityFuzzUnbalanced(uint tknRemoved, uint imbalanceBias) public {
        uint[] memory amounts = new uint[](2);
        
        // limit remove liquidity to account for slippage
        amounts[0] = bound(tknRemoved, 0, 950e18); 
        amounts[1] = amounts[0];
        imbalanceBias = bound(imbalanceBias,0,10e18);
       
        vm.prank(user2);
        well.swapFrom(tokens[0], tokens[1], imbalanceBias, 0, user2);
        vm.stopPrank();

        vm.startPrank(user);
        
        uint[] memory balancePre = new uint[](2);
        balancePre[0] = tokens[0].balanceOf(address(well));
        balancePre[1] = tokens[1].balanceOf(address(well));

        uint userLPBalance = well.balanceOf(user);
        cp = new ConstantProduct2();
        bytes memory data = "";
        uint[] memory balances = new uint[](2);
        uint lpAmountIn = well.getRemoveLiquidityImbalancedIn(amounts);
        balances[0] = tokens[0].balanceOf(address(well)) - amounts[0];
        balances[1] = tokens[1].balanceOf(address(well)) - amounts[1];

        uint newLpTokenSupply = cp.getLpTokenSupply(balances,data);
        uint totalSupply = well.totalSupply();
        uint amountOut = totalSupply - newLpTokenSupply;
        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(amountOut,amounts);
        uint[] memory minAmt = new uint[](2);
        well.removeLiquidity(amountOut,minAmt,user);

        assertEq(well.balanceOf(user), userLPBalance - lpAmountIn, "Incorrect lp output");

        assertEq(tokens[0].balanceOf(user), amounts[0], "Incorrect token0 user balance");
        assertEq(tokens[1].balanceOf(user), amounts[1], "Incorrect token1 user balance");
        assertEq(tokens[0].balanceOf(address(well)), balancePre[0] - amounts[0], "Incorrect token0 well balance");
        assertEq(tokens[1].balanceOf(address(well)), balancePre[1] - amounts[1], "Incorrect token1 well balance");

    }

    
}
