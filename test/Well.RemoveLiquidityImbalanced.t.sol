/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";


contract RemoveLiquidityImbalancedTest is TestHelper {
    uint[] tokenAmountsOut;
    
    // Shared pricing function
    ConstantProduct2 cp;
    bytes constant data = "";

    event RemoveLiquidity(uint lpAmountIn, uint[] tokenAmountsOut);

    function setUp() public {
        cp = new ConstantProduct2();
        setupWell(2);
        addLiquidityEqualAmount(user, 1000 * 1e18);
        tokenAmountsOut.push(500 * 1e18);
        tokenAmountsOut.push(506 * 1e17);
    }

    /// @dev
    function test_getRemoveLiquidityImbalancedOut() public {
        uint lpAmountIn = well.getRemoveLiquidityImbalancedIn(tokenAmountsOut);
        assertEq(lpAmountIn, 580 * 1e27);
    }

    /// @dev
    function test_removeLiquidityImbalanced() prank(user) public {
        uint maxLPAmountIn = 580 * 1e27;

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(maxLPAmountIn, tokenAmountsOut);

        well.removeLiquidityImbalanced(maxLPAmountIn, tokenAmountsOut, user);

        assertEq(well.balanceOf(user), (2000 - 580) * 1e27);

        assertEq(tokens[0].balanceOf(user), tokenAmountsOut[0], "incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user), tokenAmountsOut[1], "incorrect token1 user amt");

        assertEq(tokens[0].balanceOf(address(well)), 1500 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 19494 * 1e17, "incorrect token0 well amt");
    }

    /// @dev
    function test_removeLiquidityImbalanced_amountOutTooHigh() prank(user) public {
        uint maxLPAmountIn = 579 * 1e27;

        vm.expectRevert("Well: slippage");
        well.removeLiquidityImbalanced(maxLPAmountIn, tokenAmountsOut, user);
    }

    /// @dev Fuzz the amount of tokens removed from the Well.
    /// NOTE: the call is performed when the pool is in a BALANCED state.
    function test_removeLiquidityImbalanced_fuzz(uint x, uint y) prank(user) public {
        // Setup amounts of liquidity to remove
        // NOTE: amounts may or may not be equal
        uint[] memory amounts = new uint[](2);
        amounts[0] = bound(x, 0, 750e18); 
        amounts[1] = bound(y, 0, 750e18);

        // Calculate change in Well balances after removing liquidity
        uint[] memory balances = new uint[](2);
        balances[0] = tokens[0].balanceOf(address(well)) - amounts[0];
        balances[1] = tokens[1].balanceOf(address(well)) - amounts[1];

        // lpAmountIn should be <= user's LP balance
        uint lpAmountIn = well.getRemoveLiquidityImbalancedIn(amounts);

        // Calculate expected LP amount to deliver by computing the new LP token
        // supply for the Well's balances after performing the removal. The `user`
        // should receive the delta.
        uint newLpTokenSupply =  cp.getLpTokenSupply(balances,data);
        uint totalSupply = well.totalSupply();
        uint amountOut = totalSupply - newLpTokenSupply;

        // Remove all of `user`'s liquidity and deliver them the tokens
        uint maxLpAmountIn = well.balanceOf(user);
        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(amountOut, amounts);
        well.removeLiquidityImbalanced(maxLpAmountIn, amounts, user);

        // `user` balance of LP tokens increases
        assertEq(well.balanceOf(user), maxLpAmountIn - lpAmountIn, "Incorrect lp output");

        // `user` balance of underlying tokens increases
        assertEq(tokens[0].balanceOf(user), amounts[0], "Incorrect token0 user balance");
        assertEq(tokens[1].balanceOf(user), amounts[1], "Incorrect token1 user balance");

        // Well's balance of underlying tokens decreases
        assertEq(tokens[0].balanceOf(address(well)), 2000e18 - amounts[0], "Incorrect token0 well balance");
        assertEq(tokens[1].balanceOf(address(well)), 2000e18 - amounts[1], "Incorrect token1 well balance");
    }
    
    /// @dev Fuzz the amount of tokens removed from the Well.
    /// NOTE: the call is performed when the pool's liquidity is in an IMBALANCED 
    /// state. A Swap is performed to create a differential.
    function test_removeLiquidityImbalanced_fuzzSwapBias(uint tknRemoved, uint imbalanceBias) public {
        // Setup amounts of liquidity to remove
        // NOTE: amounts[0] is bounded at 1 to prevent slippage overflow
        // failure, bug fix in progress
        uint[] memory amounts = new uint[](2);
        amounts[0] = bound(tknRemoved, 1, 950e18);
        amounts[1] = amounts[0];
        imbalanceBias = bound(imbalanceBias, 0, 40e18);
       
        // `user2` performs a swap to imbalance the pool by `imbalanceBias`
        vm.prank(user2);
        well.swapFrom(tokens[0], tokens[1], imbalanceBias, 0, user2);
        vm.stopPrank();

        // `user` has LP tokens and will perform a `removeLiquidityImbalanced` call
        vm.startPrank(user);
        
        uint[] memory preWellBalance = new uint[](2);
        preWellBalance[0] = tokens[0].balanceOf(address(well));
        preWellBalance[1] = tokens[1].balanceOf(address(well));

        uint[] memory preUserBalance = new uint[](2);
        preUserBalance[0] = tokens[0].balanceOf(address(user));
        preUserBalance[1] = tokens[1].balanceOf(address(user));

        // Calculate change in Well balances after removing liquidity
        uint[] memory balances = new uint[](2);
        balances[0] = preWellBalance[0] - amounts[0];
        balances[1] = preWellBalance[1] - amounts[1];
        
        // lpAmountIn should be <= user's LP balance
        uint lpAmountIn = well.getRemoveLiquidityImbalancedIn(amounts);

        // Calculate expected LP amount to deliver by computing the new LP token
        // supply for the Well's balances after performing the removal. The `user`
        // should receive the delta.
        uint newLpTokenSupply = cp.getLpTokenSupply(balances, data);
        uint lpAmountOut = well.totalSupply() - newLpTokenSupply;

        // Remove all of `user`'s liquidity and deliver them the tokens
        uint maxLpAmountIn = well.balanceOf(user);
        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(lpAmountOut, amounts);
        well.removeLiquidityImbalanced(maxLpAmountIn, amounts, user);

        // `user` balance of LP tokens increases
        assertEq(well.balanceOf(user), maxLpAmountIn - lpAmountIn, "Incorrect lp output");

        // `user` balance of underlying tokens increases
        assertEq(tokens[0].balanceOf(user), preUserBalance[0] + amounts[0], "Incorrect token0 user balance");
        assertEq(tokens[1].balanceOf(user), preUserBalance[1] + amounts[1], "Incorrect token1 user balance");
        
        // Well's balance of underlying tokens decreases
        assertEq(tokens[0].balanceOf(address(well)), preWellBalance[0] - amounts[0], "Incorrect token0 well balance");
        assertEq(tokens[1].balanceOf(address(well)), preWellBalance[1] - amounts[1], "Incorrect token1 well balance");
    }
}
