// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TestHelper, ConstantProduct2, Balances} from "test/TestHelper.sol";
import {IWell} from "src/interfaces/IWell.sol";
import {IWellErrors} from "src/interfaces/IWellErrors.sol";

contract WellRemoveLiquidityImbalancedTest is TestHelper {
    event RemoveLiquidity(uint256 lpAmountIn, uint256[] tokenAmountsOut, address recipient);

    uint256[] tokenAmountsOut;
    uint256 requiredLpAmountIn;

    // Setup
    ConstantProduct2 cp;
    uint256 constant addedLiquidity = 1000 * 1e18;

    function setUp() public {
        cp = new ConstantProduct2();
        setupWell(2);

        // Add liquidity. `user` now has (2 * 1000 * 1e27) LP tokens
        addLiquidityEqualAmount(user, addedLiquidity);

        // Shared removal amounts
        tokenAmountsOut.push(500 * 1e18); // 500   token0
        tokenAmountsOut.push(506 * 1e17); //  50.6 token1
        requiredLpAmountIn = 290 * 1e24; // LP needed to remove `tokenAmountsOut`
    }

    /// @dev Assumes use of ConstantProduct2
    function test_getRemoveLiquidityImbalancedIn() public {
        uint256 lpAmountIn = well.getRemoveLiquidityImbalancedIn(tokenAmountsOut);
        assertEq(lpAmountIn, requiredLpAmountIn);
    }

    /// @dev not enough LP to receive `tokenAmountsOut`
    function test_removeLiquidityImbalanced_revertIf_notEnoughLP() public prank(user) {
        uint256 maxLpAmountIn = 5 * 1e24;
        vm.expectRevert(abi.encodeWithSelector(IWellErrors.SlippageIn.selector, requiredLpAmountIn, maxLpAmountIn));
        well.removeLiquidityImbalanced(maxLpAmountIn, tokenAmountsOut, user, type(uint256).max);
    }

    function test_removeLiquidityImbalanced_revertIf_expired() public {
        vm.expectRevert(IWellErrors.Expired.selector);
        well.removeLiquidityImbalanced(0, new uint256[](2), user, block.timestamp - 1);
    }

    /// @dev Base case
    function test_removeLiquidityImbalanced() public prank(user) {
        Balances memory userBalanceBefore = getBalances(user, well);

        uint256 initialLpAmount = userBalanceBefore.lp;
        uint256 maxLpAmountIn = requiredLpAmountIn;

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(maxLpAmountIn, tokenAmountsOut, user);
        well.removeLiquidityImbalanced(maxLpAmountIn, tokenAmountsOut, user, type(uint256).max);

        Balances memory userBalanceAfter = getBalances(user, well);
        Balances memory wellBalanceAfter = getBalances(address(well), well);

        // `user` balance of LP tokens decreases
        assertEq(userBalanceAfter.lp, initialLpAmount - maxLpAmountIn);

        // `user` balance of underlying tokens increases
        // assumes initial balance of zero
        assertEq(userBalanceAfter.tokens[0], tokenAmountsOut[0], "Incorrect token0 user balance");
        assertEq(userBalanceAfter.tokens[1], tokenAmountsOut[1], "Incorrect token1 user balance");

        // Well's reserve of underlying tokens decreases
        assertEq(wellBalanceAfter.tokens[0], 1500 * 1e18, "Incorrect token0 well reserve");
        assertEq(wellBalanceAfter.tokens[1], 19_494 * 1e17, "Incorrect token1 well reserve");
        checkInvariant(address(well));
    }

    /// @dev Fuzz test: EQUAL token reserves, IMBALANCED removal
    /// The Well contains equal reserves of all underlying tokens before execution.
    function testFuzz_removeLiquidityImbalanced(uint256 a0, uint256 a1) public prank(user) {
        // Setup amounts of liquidity to remove
        // NOTE: amounts may or may not be equal
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = bound(a0, 0, 750e18);
        amounts[1] = bound(a1, 0, 750e18);

        Balances memory wellBalanceBeforeRemoveLiquidity = getBalances(address(well), well);
        Balances memory userBalanceBeforeRemoveLiquidity = getBalances(user, well);
        // Calculate change in Well reserves after removing liquidity
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = wellBalanceBeforeRemoveLiquidity.tokens[0] - amounts[0];
        reserves[1] = wellBalanceBeforeRemoveLiquidity.tokens[1] - amounts[1];

        // lpAmountIn should be <= umaxLpAmountIn
        uint256 maxLpAmountIn = userBalanceBeforeRemoveLiquidity.lp;
        uint256 lpAmountIn = well.getRemoveLiquidityImbalancedIn(amounts);

        // Calculate the new LP token supply after the Well's reserves are changed.
        // The delta `lpAmountBurned` is the amount of LP that should be burned
        // when this liquidity is removed.
        uint256 newLpTokenSupply = cp.calcLpTokenSupply(reserves, "");
        uint256 lpAmountBurned = well.totalSupply() - newLpTokenSupply;

        // Remove all of `user`'s liquidity and deliver them the tokens
        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(lpAmountBurned, amounts, user);
        well.removeLiquidityImbalanced(maxLpAmountIn, amounts, user, type(uint256).max);

        Balances memory userBalanceAfterRemoveLiquidity = getBalances(user, well);
        Balances memory wellBalanceAfterRemoveLiquidity = getBalances(address(well), well);

        // `user` balance of LP tokens decreases
        assertEq(userBalanceAfterRemoveLiquidity.lp, maxLpAmountIn - lpAmountIn, "Incorrect lp output");

        // `user` balance of underlying tokens increases
        assertEq(userBalanceAfterRemoveLiquidity.tokens[0], amounts[0], "Incorrect token0 user balance");
        assertEq(userBalanceAfterRemoveLiquidity.tokens[1], amounts[1], "Incorrect token1 user balance");

        // Well's reserve of underlying tokens decreases
        // Equal amount of liquidity of 1000e18 were added in the setup function hence the
        // well's reserves here are 2000e18 minus the amounts removed, as the initial liquidity
        // is 1000e18 of each token.
        assertEq(
            wellBalanceAfterRemoveLiquidity.tokens[0],
            (initialLiquidity + addedLiquidity) - amounts[0],
            "Incorrect token0 well reserve"
        );
        assertEq(
            wellBalanceAfterRemoveLiquidity.tokens[1],
            (initialLiquidity + addedLiquidity) - amounts[1],
            "Incorrect token1 well reserve"
        );
        checkInvariant(address(well));
    }

    /// @dev Fuzz test: UNEQUAL token reserves, IMBALANCED removal
    /// A Swap is performed by `user2` that imbalances the pool by `imbalanceBias`
    /// before liquidity is removed by `user`.
    function testFuzz_removeLiquidityImbalanced_withSwap(uint256 a0, uint256 imbalanceBias) public {
        // Setup amounts of liquidity to remove
        // NOTE: amounts[0] is bounded at 1 to prevent slippage overflow
        // failure, bug fix in progress
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = bound(a0, 1, 950e18);
        amounts[1] = amounts[0];
        imbalanceBias = bound(imbalanceBias, 0, 40e18);

        // `user2` performs a swap to imbalance the pool by `imbalanceBias`
        vm.prank(user2);
        well.swapFrom(tokens[0], tokens[1], imbalanceBias, 0, user2, type(uint256).max);

        // `user` has LP tokens and will perform a `removeLiquidityImbalanced` call
        vm.startPrank(user);

        Balances memory wellBalanceBefore = getBalances(address(well), well);
        Balances memory userBalanceBefore = getBalances(user, well);

        // Calculate change in Well reserves after removing liquidity
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = wellBalanceBefore.tokens[0] - amounts[0];
        reserves[1] = wellBalanceBefore.tokens[1] - amounts[1];

        // lpAmountIn should be <= user's LP balance
        uint256 lpAmountIn = well.getRemoveLiquidityImbalancedIn(amounts);

        // Calculate the new LP token supply after the Well's reserves are changed.
        // The delta `lpAmountBurned` is the amount of LP that should be burned
        // when this liquidity is removed.
        uint256 newLpTokenSupply = cp.calcLpTokenSupply(reserves, "");
        uint256 lpAmountBurned = well.totalSupply() - newLpTokenSupply;

        // Remove some of `user`'s liquidity and deliver them the tokens
        uint256 maxLpAmountIn = userBalanceBefore.lp;
        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(lpAmountBurned, amounts, user);
        well.removeLiquidityImbalanced(maxLpAmountIn, amounts, user, type(uint256).max);

        Balances memory wellBalanceAfter = getBalances(address(well), well);
        Balances memory userBalanceAfter = getBalances(user, well);

        // `user` balance of LP tokens decreases
        assertEq(userBalanceAfter.lp, maxLpAmountIn - lpAmountIn, "Incorrect lp output");

        // `user` balance of underlying tokens increases
        assertEq(userBalanceAfter.tokens[0], userBalanceBefore.tokens[0] + amounts[0], "Incorrect token0 user balance");
        assertEq(userBalanceAfter.tokens[1], userBalanceBefore.tokens[1] + amounts[1], "Incorrect token1 user balance");

        // Well's reserve of underlying tokens decreases
        assertEq(wellBalanceAfter.tokens[0], wellBalanceBefore.tokens[0] - amounts[0], "Incorrect token0 well reserve");
        assertEq(wellBalanceAfter.tokens[1], wellBalanceBefore.tokens[1] - amounts[1], "Incorrect token1 well reserve");
        checkInvariant(address(well));
    }
}
