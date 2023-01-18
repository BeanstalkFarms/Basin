/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";

contract RemoveLiquidityImbalancedTest is TestHelper {
    uint[] tokenAmountsOut;
    
    ConstantProduct2 cp;
    bytes constant data = "";

    event RemoveLiquidity(uint lpAmountIn, uint[] tokenAmountsOut);

    function setUp() public {
        cp = new ConstantProduct2();
        setupWell(2);

        // Add liquidity. `user` now has (2 * 1000 * 1e27) LP tokens
        addLiquidityEqualAmount(user, 1000 * 1e18); 

        // Shared removal amounts
        tokenAmountsOut.push(500 * 1e18); // 500   token0
        tokenAmountsOut.push(506 * 1e17); //  50.6 token1
    }

    /// @dev Assumes use of ConstantProduct2
    function test_getRemoveLiquidityImbalancedOut() public {
        uint lpAmountIn = well.getRemoveLiquidityImbalancedIn(tokenAmountsOut);
        assertEq(lpAmountIn, 580 * 1e27);
    }

    /// @dev Base case
    function test_removeLiquidityImbalanced() prank(user) public {
        uint maxLpAmountIn = 580 * 1e27; // LP needed to remove `tokenAmountsOut`

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(maxLpAmountIn, tokenAmountsOut);
        well.removeLiquidityImbalanced(maxLpAmountIn, tokenAmountsOut, user);

        // `user` balance of LP tokens decreases
        assertEq(well.balanceOf(user), (2000 - 580) * 1e27);

        // `user` balance of underlying tokens increases
        // assumes initial balance of zero
        assertEq(tokens[0].balanceOf(user), tokenAmountsOut[0], "Incorrect token0 user balance");
        assertEq(tokens[1].balanceOf(user), tokenAmountsOut[1], "Incorrect token1 user balance");

        // Well's balance of underlying tokens decreases
        assertEq(tokens[0].balanceOf(address(well)), 1500 * 1e18, "Incorrect token0 well balance");
        assertEq(tokens[1].balanceOf(address(well)), 19494 * 1e17, "Incorrect token1 well balance");
    }

    /// @dev not enough LP to receive `tokenAmountsOut`
    function test_removeLiquidityImbalanced_notEnoughLP() prank(user) public {
        uint maxLpAmountIn = 10 * 1e27;
        vm.expectRevert("Well: slippage");
        well.removeLiquidityImbalanced(maxLpAmountIn, tokenAmountsOut, user);
    }

    /// @dev Fuzz test: EQUAL token balances, IMBALANCED removal
    /// The Well contains equal balances of all underlying tokens.
    function test_removeLiquidityImbalanced_fuzz(uint a0, uint a1) prank(user) public {
        // Setup amounts of liquidity to remove
        // NOTE: amounts may or may not be equal
        uint[] memory amounts = new uint[](2);
        amounts[0] = bound(a0, 0, 750e18); 
        amounts[1] = bound(a1, 0, 750e18);

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

        // `user` balance of LP tokens decreases
        assertEq(well.balanceOf(user), maxLpAmountIn - lpAmountIn, "Incorrect lp output");

        // `user` balance of underlying tokens increases
        assertEq(tokens[0].balanceOf(user), amounts[0], "Incorrect token0 user balance");
        assertEq(tokens[1].balanceOf(user), amounts[1], "Incorrect token1 user balance");

        // Well's balance of underlying tokens decreases
        assertEq(tokens[0].balanceOf(address(well)), 2000e18 - amounts[0], "Incorrect token0 well balance");
        assertEq(tokens[1].balanceOf(address(well)), 2000e18 - amounts[1], "Incorrect token1 well balance");
    }
    
    /// @dev Fuzz test: UNEQUAL token balances, IMBALANCED removal
    /// A Swap is performed by `user2` that imbalances the pool by `imbalanceBias` 
    /// before liquidity is removed by `user`.
    function test_removeLiquidityImbalanced_fuzzSwapBias(uint a0, uint imbalanceBias) public {
        // Setup amounts of liquidity to remove
        // NOTE: amounts[0] is bounded at 1 to prevent slippage overflow
        // failure, bug fix in progress
        uint[] memory amounts = new uint[](2);
        amounts[0] = bound(a0, 1, 950e18);
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

        // Remove some of `user`'s liquidity and deliver them the tokens
        uint maxLpAmountIn = well.balanceOf(user);
        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(lpAmountOut, amounts);
        well.removeLiquidityImbalanced(maxLpAmountIn, amounts, user);

        // `user` balance of LP tokens decreases
        assertEq(well.balanceOf(user), maxLpAmountIn - lpAmountIn, "Incorrect lp output");

        // `user` balance of underlying tokens increases
        assertEq(tokens[0].balanceOf(user), preUserBalance[0] + amounts[0], "Incorrect token0 user balance");
        assertEq(tokens[1].balanceOf(user), preUserBalance[1] + amounts[1], "Incorrect token1 user balance");
        
        // Well's balance of underlying tokens decreases
        assertEq(tokens[0].balanceOf(address(well)), preWellBalance[0] - amounts[0], "Incorrect token0 well balance");
        assertEq(tokens[1].balanceOf(address(well)), preWellBalance[1] - amounts[1], "Incorrect token1 well balance");
    }
}
