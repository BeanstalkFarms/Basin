// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, ConstantProduct2, IERC20, Balances} from "test/TestHelper.sol";
import {LiquiditySnapshot, AddLiquidityAction, RemoveLiquidityAction, LiquidityHelper} from "test/LiquidityHelper.sol";

contract WellRemoveLiquidityTest is LiquidityHelper {
    ConstantProduct2 cp;
    bytes constant data = "";
    uint constant addedLiquidity = 1000 * 1e18;

    function setUp() public {
        cp = new ConstantProduct2();
        setupWell(2);

        // Add liquidity. `user` now has (2 * 1000 * 1e27) LP tokens
        addLiquidityEqualAmount(user, addedLiquidity);
    }

    /// @dev ensure that Well liq was initialized correctly in {setUp}
    /// currently, liquidity is added in {TestHelper} and above
    function test_liquidityInitialized() public {
        IERC20[] memory tokens = well.tokens();
        for (uint i = 0; i < tokens.length; i++) {
            assertEq(tokens[i].balanceOf(address(well)), initialLiquidity + addedLiquidity, "incorrect token reserve");
        }
        assertEq(well.totalSupply(), 4000 * 1e27, "incorrect totalSupply");
    }

    /// @dev getRemoveLiquidityOut: remove to equal amounts of underlying
    /// since the tokens in the Well are balanced, user receives equal amounts
    function test_getRemoveLiquidityOut() public {
        uint[] memory amountsOut = well.getRemoveLiquidityOut(2000 * 1e27);
        for (uint i = 0; i < tokens.length; i++) {
            assertEq(amountsOut[i], 1000 * 1e18, "incorrect getRemoveLiquidityOut");
        }
    }

    /// @dev removeLiquidity: remove to equal amounts of underlying
    function test_removeLiquidity() public prank(user) {
        uint lpAmountIn = 2000 * 1e27;
        uint[] memory amountsOut = new uint[](2);
        amountsOut[0] = 1000 * 1e18;
        amountsOut[1] = 1000 * 1e18;

        LiquiditySnapshot memory before;
        RemoveLiquidityAction memory action;

        action.amounts = amountsOut;
        action.lpAmountIn = lpAmountIn;
        action.recipient = user;
        action.fees = new uint[](2);

        (before, action) = beforeRemoveLiquidity(action);
        well.removeLiquidity(lpAmountIn, amountsOut, user);

        afterRemoveLiquidity(before, action);
    }

    /// @dev removeLiquidity: reverts when user tries to remove too much of an underlying token
    function test_removeLiquidity_amountOutTooHigh() public prank(user) {
        uint lpAmountIn = 2000 * 1e18;
        uint[] memory amountsOut = new uint[](2);
        amountsOut[0] = 1001 * 1e18; // too high
        amountsOut[1] = 1000 * 1e18;

        vm.expectRevert("Well: slippage");
        well.removeLiquidity(lpAmountIn, amountsOut, user);
    }

    /// @dev Fuzz test: EQUAL token reserves, BALANCED removal
    /// The Well contains equal reserves of all underlying tokens before execution.
    function test_removeLiquidity_fuzz(uint a0) public prank(user) {
        // Setup amounts of liquidity to remove
        // NOTE: amounts may or may not match the maximum removable by `user`.
        uint[] memory amounts = new uint[](2);
        amounts[0] = bound(a0, 0, 1000e18);
        amounts[1] = amounts[0];

        LiquiditySnapshot memory before;
        RemoveLiquidityAction memory action;
        uint lpAmountIn = well.getRemoveLiquidityImbalancedIn(amounts);

        action.amounts = amounts;
        action.lpAmountIn = lpAmountIn;
        action.recipient = user;
        action.fees = new uint[](2);

        (before, action) = beforeRemoveLiquidity(action);
        well.removeLiquidity(lpAmountIn, amounts, user);

        afterRemoveLiquidity(before, action);
    }

    /// @dev Fuzz test: UNEQUAL token reserves, BALANCED removal
    /// A Swap is performed by `user2` that imbalances the pool by `imbalanceBias`
    /// before liquidity is removed by `user`.
    function test_removeLiquidity_fuzzSwapBias(uint lpAmountBurned, uint imbalanceBias) public {
        Balances memory userBalanceBeforeRemoveLiquidity = getBalances(user, well);

        uint maxLpAmountIn = userBalanceBeforeRemoveLiquidity.lp;
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

        LiquiditySnapshot memory before;
        RemoveLiquidityAction memory action;

        action.amounts = tokenAmountsOut;
        action.lpAmountIn = lpAmountBurned;
        action.recipient = user;
        action.fees = new uint[](2);

        (before, action) = beforeRemoveLiquidity(action);
        well.removeLiquidity(lpAmountBurned, tokenAmountsOut, user);

        afterRemoveLiquidity(before, action);
    }
}
