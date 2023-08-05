// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TestHelper, ConstantProduct2, IERC20, Balances} from "test/TestHelper.sol";
import {IWell} from "src/interfaces/IWell.sol";
import {IWellErrors} from "src/interfaces/IWellErrors.sol";

contract WellRemoveLiquidityOneTokenTest is TestHelper {
    event RemoveLiquidityOneToken(uint256 lpAmountIn, IERC20 tokenOut, uint256 tokenAmountOut, address recipient);

    ConstantProduct2 cp;
    uint256 constant addedLiquidity = 1000 * 1e18;

    function setUp() public {
        cp = new ConstantProduct2();
        setupWell(2);

        // Add liquidity. `user` now has (2 * 1000 * 1e27) LP tokens
        addLiquidityEqualAmount(user, addedLiquidity);
    }

    /// @dev Assumes use of ConstantProduct2
    function test_getRemoveLiquidityOneTokenOut() public {
        uint256 amountOut = well.getRemoveLiquidityOneTokenOut(500 * 1e24, tokens[0]);
        assertEq(amountOut, 875 * 1e18, "incorrect tokenOut");
    }

    /// @dev not enough tokens received for `lpAmountIn`.
    function test_removeLiquidityOneToken_revertIf_amountOutTooLow() public prank(user) {
        uint256 lpAmountIn = 500 * 1e15;
        uint256 minTokenAmountOut = 876 * 1e18; // too high
        uint256 amountOut = well.getRemoveLiquidityOneTokenOut(lpAmountIn, tokens[0]);

        vm.expectRevert(abi.encodeWithSelector(IWellErrors.SlippageOut.selector, amountOut, minTokenAmountOut));
        well.removeLiquidityOneToken(lpAmountIn, tokens[0], minTokenAmountOut, user, type(uint256).max);
    }

    function test_removeLiquidityOneToken_revertIf_expired() public {
        vm.expectRevert(IWellErrors.Expired.selector);
        well.removeLiquidityOneToken(0, tokens[0], 0, user, block.timestamp - 1);
    }

    /// @dev Base case
    function test_removeLiquidityOneToken() public prank(user) {
        uint256 lpAmountIn = 500 * 1e24;
        uint256 minTokenAmountOut = 875 * 1e18;

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidityOneToken(lpAmountIn, tokens[0], minTokenAmountOut, user);

        uint256 amountOut =
            well.removeLiquidityOneToken(lpAmountIn, tokens[0], minTokenAmountOut, user, type(uint256).max);

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
        checkInvariant(address(well));
    }

    /// @dev Fuzz test: EQUAL token reserves, IMBALANCED removal
    /// The Well contains equal reserves of all underlying tokens before execution.
    function testFuzz_removeLiquidityOneToken(uint256 a0) public prank(user) {
        // Assume we're removing tokens[0]
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = bound(a0, 1e6, 750e18);
        amounts[1] = 0;

        Balances memory userBalanceBeforeRemoveLiquidity = getBalances(user, well);
        uint256 userLpBalance = userBalanceBeforeRemoveLiquidity.lp;

        // Find the LP amount that should be burned given the fuzzed
        // amounts. Works even though only amounts[0] is set.
        uint256 lpAmountIn = well.getRemoveLiquidityImbalancedIn(amounts);

        Balances memory wellBalanceBeforeRemoveLiquidity = getBalances(address(well), well);

        // Calculate change in Well reserves after removing liquidity
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = wellBalanceBeforeRemoveLiquidity.tokens[0] - amounts[0];
        reserves[1] = wellBalanceBeforeRemoveLiquidity.tokens[1] - amounts[1]; // should stay the same

        // Calculate the new LP token supply after the Well's reserves are changed.
        // The delta `lpAmountBurned` is the amount of LP that should be burned
        // when this liquidity is removed.
        uint256 newLpTokenSupply = cp.calcLpTokenSupply(reserves, "");
        uint256 lpAmountBurned = well.totalSupply() - newLpTokenSupply;

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidityOneToken(lpAmountBurned, tokens[0], amounts[0], user);
        well.removeLiquidityOneToken(lpAmountIn, tokens[0], 0, user, type(uint256).max); // no minimum out

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
        checkInvariant(address(well));
    }

    // TODO: fuzz test: imbalanced ratio of tokens
}
