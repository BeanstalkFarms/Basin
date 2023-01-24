/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";

contract WellRemoveLiquidityTest is TestHelper {
    ConstantProduct2 cp;
    bytes constant data = "";

    event RemoveLiquidity(uint lpAmountIn, uint[] tokenAmountsOut);

    function setUp() public {
        cp = new ConstantProduct2();
        setupWell(2);
        
        // Add liquidity. `user` now has (2 * 1000 * 1e27) LP tokens
        addLiquidityEqualAmount(user, 1000 * 1e18);
    }

    /// @dev ensure that Well liq was initialized correctly in {setUp}
    /// currently, liquidity is added in {TestHelper} and above
    function test_liquidityInitialized() public {
        IERC20[] memory tokens = well.tokens();
        for(uint i = 0; i < tokens.length; i++) {
            assertEq(tokens[i].balanceOf(address(well)), 2000 * 1e18, "incorrect token reserve");
        }
        assertEq(well.totalSupply(), 4000 * 1e27, "incorrect totalSupply");
    }

    /// @dev getRemoveLiquidityOut: remove to equal amounts of underlying
    /// since the tokens in the Well are balanced, user receives equal amounts
    function test_getRemoveLiquidityOut() public {
        uint[] memory amountsOut = well.getRemoveLiquidityOut(2000 * 1e27);
        for (uint i = 0; i < tokens.length; i++) 
            assertEq(amountsOut[i], 1000 * 1e18, "incorrect getRemoveLiquidityOut");
    }

    /// @dev removeLiquidity: remove to equal amounts of underlying
    function test_removeLiquidity() prank(user) public {
        uint lpAmountIn = 2000 * 1e27;
        uint[] memory amountsOut = new uint[](2);
        amountsOut[0] = 1000 * 1e18;
        amountsOut[1] = 1000 * 1e18;
        
        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(lpAmountIn, amountsOut);
        well.removeLiquidity(lpAmountIn, amountsOut, user);

        // `user` balance of LP tokens decreases
        assertEq(well.balanceOf(user), 0);

        // `user` balance of underlying tokens increases
        // assumes initial balance of zero
        assertEq(tokens[0].balanceOf(user), amountsOut[0], "incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user), amountsOut[1], "incorrect token1 user amt");

        // Well's reserve of underlying tokens decreases
        assertEq(tokens[0].balanceOf(address(well)), (2000 - 1000) * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), (2000 - 1000) * 1e18, "incorrect token1 well amt");
    }

    /// @dev removeLiquidity: reverts when user tries to remove too much of an underlying token
    function test_removeLiquidity_amountOutTooHigh() prank(user) public {
        uint lpAmountIn = 2000 * 1e18;
        uint[] memory amountsOut = new uint[](2);
        amountsOut[0] = 1001 * 1e18; // too high
        amountsOut[1] = 1000 * 1e18;

        vm.expectRevert("Well: slippage");
        well.removeLiquidity(lpAmountIn, amountsOut, user);
    }

    /// @dev Fuzz test: EQUAL token reserves, BALANCED removal
    /// The Well contains equal reserves of all underlying tokens before execution.
    function test_removeLiquidity_fuzz(uint a0) prank(user) public {
        // Setup amounts of liquidity to remove
        // NOTE: amounts may or may not match the maximum removable by `user`.
        uint[] memory amounts = new uint[](2);
        amounts[0] = bound(a0, 0, 1000e18);
        amounts[1] = amounts[0];
        
        // Calculate change in Well reserves after removing liquidity
        uint[] memory reserves = new uint[](2);
        reserves[0] = tokens[0].balanceOf(address(well)) - amounts[0];
        reserves[1] = tokens[1].balanceOf(address(well)) - amounts[1];
        
        // lpAmountIn should be <= maxLpAmountIn
        uint maxLpAmountIn = well.balanceOf(user);
        uint lpAmountIn = well.getRemoveLiquidityImbalancedIn(amounts);

        // Calculate the new LP token supply after the Well's reserves are changed.
        // The delta `lpAmountBurned` is the amount of LP that should be burned
        // when this liquidity is removed.
        uint newLpTokenSupply = cp.calcLpTokenSupply(reserves, data);
        uint lpAmountBurned = well.totalSupply() - newLpTokenSupply;

        // Remove some of `user`'s liquidity and deliver them the tokens
        uint[] memory minAmountsOut = new uint[](2);
        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(lpAmountBurned, amounts);
        well.removeLiquidity(lpAmountBurned, minAmountsOut, user);

        // `user` balance of LP tokens decreases
        assertEq(well.balanceOf(user), maxLpAmountIn - lpAmountIn, "Incorrect lp output");

        // `user` balance of underlying tokens increases
        assertEq(tokens[0].balanceOf(user), amounts[0], "Incorrect token0 user balance");
        assertEq(tokens[1].balanceOf(user), amounts[1], "Incorrect token1 user balance");

        // Well's reserve of underlying tokens decreases
        assertEq(tokens[0].balanceOf(address(well)), 2000e18 - amounts[0], "Incorrect token0 well reserve");
        assertEq(tokens[1].balanceOf(address(well)), 2000e18 - amounts[1], "Incorrect token1 well reserve");
    }

    /// @dev Fuzz test: UNEQUAL token reserves, BALANCED removal
    /// A Swap is performed by `user2` that imbalances the pool by `imbalanceBias` 
    /// before liquidity is removed by `user`.
    function test_removeLiquidity_fuzzSwapBias(uint lpAmountBurned, uint imbalanceBias) public {
        uint maxLpAmountIn = well.balanceOf(user);
        lpAmountBurned = bound(lpAmountBurned, 100, maxLpAmountIn); 
        imbalanceBias = bound(imbalanceBias, 0, 10e18);

        // `user2` performs a swap to imbalance the pool by `imbalanceBias`
        vm.prank(user2);
        well.swapFrom(tokens[0], tokens[1], imbalanceBias, 0, user2);
        vm.stopPrank();

        // `user` has LP tokens and will perform a `removeLiquidity` call
        vm.startPrank(user);

        uint[] memory tokenAmountsOut = new uint[](2);
        tokenAmountsOut = well.getRemoveLiquidityOut(lpAmountBurned);

        // Calculate change in Well reserves after removing liquidity
        uint[] memory reserves = new uint[](2);
        reserves[0] = tokens[0].balanceOf(address(well)) - tokenAmountsOut[0];
        reserves[1] = tokens[1].balanceOf(address(well)) - tokenAmountsOut[1];

        // Remove some of `user`'s liquidity and deliver them the tokens
        uint[] memory minAmountOut = new uint[](2);
        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(lpAmountBurned, tokenAmountsOut);
        well.removeLiquidity(lpAmountBurned, minAmountOut, user);

        // `user` balance of LP tokens decreases
        assertEq(well.balanceOf(user), maxLpAmountIn - lpAmountBurned, "Incorrect lp output");

        // `user` balance of underlying tokens increases
        // NOTE: assumes the `user` starts with 0 balance
        assertEq(tokens[0].balanceOf(user), tokenAmountsOut[0], "Incorrect token0 user balance");
        assertEq(tokens[1].balanceOf(user), tokenAmountsOut[1], "Incorrect token1 user balance");

        // Well's reserve of underlying tokens decreases
        assertEq(tokens[0].balanceOf(address(well)), reserves[0], "Incorrect token0 well reserve");
        assertEq(tokens[1].balanceOf(address(well)), reserves[1], "Incorrect token1 well reserve");
    }
}
