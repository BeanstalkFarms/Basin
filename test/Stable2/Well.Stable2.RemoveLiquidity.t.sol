// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, Stable2, IERC20, Balances} from "test/TestHelper.sol";
import {Snapshot, AddLiquidityAction, RemoveLiquidityAction, LiquidityHelper} from "test/LiquidityHelper.sol";
import {IWell} from "src/interfaces/IWell.sol";
import {IWellErrors} from "src/interfaces/IWellErrors.sol";
import {Stable2LUT1} from "src/functions/StableLUT/Stable2LUT1.sol";

contract WellStable2RemoveLiquidityTest is LiquidityHelper {
    Stable2 ss;
    bytes constant data = "";
    uint256 constant addedLiquidity = 1000 * 1e18;

    function setUp() public {
        address lut = address(new Stable2LUT1());
        ss = new Stable2(lut);
        setupStable2Well();

        // Add liquidity. `user` now has (2 * 1000 * 1e27) LP tokens
        addLiquidityEqualAmount(user, addedLiquidity);
    }

    /// @dev ensure that Well liq was initialized correctly in {setUp}
    /// currently, liquidity is added in {TestHelper} and above
    function test_liquidityInitialized() public view {
        IERC20[] memory tokens = well.tokens();
        for (uint256 i; i < tokens.length; i++) {
            assertEq(tokens[i].balanceOf(address(well)), initialLiquidity + addedLiquidity, "incorrect token reserve");
        }
        assertEq(well.totalSupply(), 4000 * 1e18, "incorrect totalSupply");
    }

    /// @dev getRemoveLiquidityOut: remove to equal amounts of underlying
    /// since the tokens in the Well are balanced, user receives equal amounts
    function test_getRemoveLiquidityOut() public view {
        uint256[] memory amountsOut = well.getRemoveLiquidityOut(1000 * 1e18);
        for (uint256 i; i < tokens.length; i++) {
            assertEq(amountsOut[i], 500 * 1e18, "incorrect getRemoveLiquidityOut");
        }
    }

    /// @dev removeLiquidity: reverts when user tries to remove too much of an underlying token
    function test_removeLiquidity_revertIf_minAmountOutTooHigh() public prank(user) {
        uint256 lpAmountIn = 1000 * 1e18;

        uint256[] memory minTokenAmountsOut = new uint256[](2);
        minTokenAmountsOut[0] = 501 * 1e18; // too high
        minTokenAmountsOut[1] = 500 * 1e18;

        vm.expectRevert(abi.encodeWithSelector(IWellErrors.SlippageOut.selector, 500 * 1e18, minTokenAmountsOut[0]));
        well.removeLiquidity(lpAmountIn, minTokenAmountsOut, user, type(uint256).max);
    }

    function test_removeLiquidity_revertIf_expired() public {
        vm.expectRevert(IWellErrors.Expired.selector);
        well.removeLiquidity(0, new uint256[](2), user, block.timestamp - 1);
    }

    /// @dev removeLiquidity: remove to equal amounts of underlying
    function test_removeLiquidity() public prank(user) {
        uint256 lpAmountIn = 1000 * 1e18;

        uint256[] memory amountsOut = new uint256[](2);
        amountsOut[0] = 500 * 1e18;
        amountsOut[1] = 500 * 1e18;

        Snapshot memory before;
        RemoveLiquidityAction memory action;

        action.amounts = amountsOut;
        action.lpAmountIn = lpAmountIn;
        action.recipient = user;
        action.fees = new uint256[](2);

        (before, action) = beforeRemoveLiquidity(action);
        well.removeLiquidity(lpAmountIn, amountsOut, user, type(uint256).max);
        afterRemoveLiquidity(before, action);
        checkInvariant(address(well));
    }

    /// @dev Fuzz test: EQUAL token reserves, BALANCED removal
    /// The Well contains equal reserves of all underlying tokens before execution.
    function test_removeLiquidity_fuzz(uint256 a0) public prank(user) {
        // Setup amounts of liquidity to remove
        // NOTE: amounts may or may not match the maximum removable by `user`.
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = bound(a0, 0, 1000e18);
        amounts[1] = amounts[0];

        Snapshot memory before;
        RemoveLiquidityAction memory action;
        uint256 lpAmountIn = well.getRemoveLiquidityImbalancedIn(amounts);

        action.amounts = amounts;
        action.lpAmountIn = lpAmountIn;
        action.recipient = user;
        action.fees = new uint256[](2);

        (before, action) = beforeRemoveLiquidity(action);
        well.removeLiquidity(lpAmountIn, amounts, user, type(uint256).max);
        afterRemoveLiquidity(before, action);

        assertLe(
            well.totalSupply(), Stable2(wellFunction.target).calcLpTokenSupply(well.getReserves(), wellFunction.data)
        );
        checkInvariant(address(well));
    }

    /// @dev Fuzz test: UNEQUAL token reserves, BALANCED removal
    /// A Swap is performed by `user2` that imbalances the pool by `imbalanceBias`
    /// before liquidity is removed by `user`.
    function test_removeLiquidity_fuzzSwapBias(uint256 lpAmountBurned, uint256 imbalanceBias) public {
        Balances memory userBalanceBeforeRemoveLiquidity = getBalances(user, well);

        uint256 maxLpAmountIn = userBalanceBeforeRemoveLiquidity.lp;
        lpAmountBurned = bound(lpAmountBurned, 100, maxLpAmountIn);
        imbalanceBias = bound(imbalanceBias, 0, 10e18);

        // `user2` performs a swap to imbalance the pool by `imbalanceBias`
        vm.prank(user2);
        well.swapFrom(tokens[0], tokens[1], imbalanceBias, 0, user2, type(uint256).max);

        // `user` has LP tokens and will perform a `removeLiquidity` call
        vm.startPrank(user);

        uint256[] memory tokenAmountsOut = new uint256[](2);
        tokenAmountsOut = well.getRemoveLiquidityOut(lpAmountBurned);

        Snapshot memory before;
        RemoveLiquidityAction memory action;

        action.amounts = tokenAmountsOut;
        action.lpAmountIn = lpAmountBurned;
        action.recipient = user;
        action.fees = new uint256[](2);

        (before, action) = beforeRemoveLiquidity(action);
        well.removeLiquidity(lpAmountBurned, tokenAmountsOut, user, type(uint256).max);
        afterRemoveLiquidity(before, action);
        checkStableSwapInvariant(address(well));
    }
}
