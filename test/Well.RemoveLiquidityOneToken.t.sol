// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, ConstantProduct2, IERC20, Balances} from "test/TestHelper.sol";
import {IWell} from "src/interfaces/IWell.sol";

contract WellRemoveLiquidityOneTokenTest is TestHelper {
    event RemoveLiquidityOneToken(uint lpAmountIn, IERC20 tokenOut, uint tokenAmountOut, address recipient);

    ConstantProduct2 cp;
    uint constant addedLiquidity = 1000 * 1e18;

    function setUp() public {
        cp = new ConstantProduct2();
        setupWell(2);

        // Add liquidity. `user` now has (2 * 1000 * 1e27) LP tokens
        addLiquidityEqualAmount(user, addedLiquidity);
    }

    /// @dev Assumes use of ConstantProduct2
    function test_getRemoveLiquidityOneTokenOut() public {
        uint amountOut = well.getRemoveLiquidityOneTokenOut(500 * 1e24, tokens[0]);
        assertEq(amountOut, 875 * 1e18, "incorrect tokenOut");
    }

    /// @dev Base case
    function test_removeLiquidityOneToken() public prank(user) {
        uint lpAmountIn = 500 * 1e24;
        uint minTokenAmountOut = 875 * 1e18;

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidityOneToken(lpAmountIn, tokens[0], minTokenAmountOut, user);

        uint amountOut = well.removeLiquidityOneToken(lpAmountIn, tokens[0], minTokenAmountOut, user);

        Balances memory userBalance = getBalances(user, well);
        Balances memory wellBalance = getBalances(address(well), well);

        assertEq(userBalance.lp, lpAmountIn, "Incorrect lpAmountIn");

        assertEq(userBalance.tokens[0], amountOut, "Incorrect token0 user balance");
        assertEq(userBalance.tokens[1], 0, "Incorrect token1 user balance");

        // Equal amount of liquidity of 1000e18 were added in the setup function hence the
        // well's reserves here are 2000e18 minus the amounts removed, as the initial liquidity
        // is 1000e18 of each token.
        assertEq(
            wellBalance.tokens[0],
            (initialLiquidity + addedLiquidity) - minTokenAmountOut,
            "Incorrect token0 well reserve"
        );
        assertEq(wellBalance.tokens[1], (initialLiquidity + addedLiquidity), "Incorrect token1 well reserve");
    }

    /// @dev not enough tokens received for `lpAmountIn`.
    function test_removeLiquidityOneToken_revertIf_amountOutTooLow() public prank(user) {
        uint lpAmountIn = 500 * 1e15;
        uint minTokenAmountOut = 876 * 1e18; // too high
        uint amountOut = well.getRemoveLiquidityOneTokenOut(lpAmountIn, tokens[0]);

        vm.expectRevert(abi.encodeWithSelector(IWell.SlippageOut.selector, amountOut, minTokenAmountOut));
        well.removeLiquidityOneToken(lpAmountIn, tokens[0], minTokenAmountOut, user);
    }

    /// @dev Fuzz test: EQUAL token reserves, IMBALANCED removal
    /// The Well contains equal reserves of all underlying tokens before execution.
    function testFuzz_removeLiquidityOneToken(uint a0) public prank(user) {
        // Assume we're removing tokens[0]
        uint[] memory amounts = new uint[](2);
        amounts[0] = bound(a0, 1e6, 750e18);
        amounts[1] = 0;

        Balances memory userBalanceBeforeRemoveLiquidity = getBalances(user, well);
        uint userLpBalance = userBalanceBeforeRemoveLiquidity.lp;

        // Find the LP amount that should be burned given the fuzzed
        // amounts. Works even though only amounts[0] is set.
        uint lpAmountIn = well.getRemoveLiquidityImbalancedIn(amounts);

        Balances memory wellBalanceBeforeRemoveLiquidity = getBalances(address(well), well);

        // Calculate change in Well reserves after removing liquidity
        uint[] memory reserves = new uint[](2);
        reserves[0] = wellBalanceBeforeRemoveLiquidity.tokens[0] - amounts[0];
        reserves[1] = wellBalanceBeforeRemoveLiquidity.tokens[1] - amounts[1]; // should stay the same

        // Calculate the new LP token supply after the Well's reserves are changed.
        // The delta `lpAmountBurned` is the amount of LP that should be burned
        // when this liquidity is removed.
        uint newLpTokenSupply = cp.calcLpTokenSupply(reserves, "");
        uint lpAmountBurned = well.totalSupply() - newLpTokenSupply;

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidityOneToken(lpAmountBurned, tokens[0], amounts[0], user);
        well.removeLiquidityOneToken(lpAmountIn, tokens[0], 0, user); // no minimum out

        Balances memory userBalanceAfterRemoveLiquidity = getBalances(user, well);
        Balances memory wellBalanceAfterRemoveLiquidity = getBalances(address(well), well);

        assertEq(userBalanceAfterRemoveLiquidity.lp, userLpBalance - lpAmountIn, "Incorrect lp output");
        assertEq(userBalanceAfterRemoveLiquidity.tokens[0], amounts[0], "Incorrect token0 user balance");
        assertEq(userBalanceAfterRemoveLiquidity.tokens[1], amounts[1], "Incorrect token1 user balance"); // should stay the same
        assertEq(
            wellBalanceAfterRemoveLiquidity.tokens[0],
            (initialLiquidity + addedLiquidity) - amounts[0],
            "Incorrect token0 well reserve"
        );
        assertEq(
            wellBalanceAfterRemoveLiquidity.tokens[1],
            (initialLiquidity + addedLiquidity) - amounts[1],
            "Incorrect token1 well reserve"
        ); // should stay the same
    }

    // TODO: fuzz test: imbalanced ratio of tokens
}
