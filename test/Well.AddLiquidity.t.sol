// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {TestHelper, IERC20, Call, Balances} from "test/TestHelper.sol";
import {ConstantProduct2, IWellFunction} from "src/functions/ConstantProduct2.sol";
import {Snapshot, AddLiquidityAction, RemoveLiquidityAction, LiquidityHelper} from "test/LiquidityHelper.sol";

contract WellAddLiquidityTest is LiquidityHelper {
    function setUp() public {
        setupWell(2);
    }

    /// @dev liquidity is initially added in {TestHelper}
    /// this will ensure that subsequent tests run correctly.
    function test_liquidityInitialized() public {
        IERC20[] memory tokens = well.tokens();
        Balances memory userBalance = getBalances(user, well);
        Balances memory wellBalance = getBalances(address(well), well);
        for (uint i = 0; i < tokens.length; i++) {
            assertEq(userBalance.tokens[i], initialLiquidity, "incorrect user token reserve");
            assertEq(wellBalance.tokens[i], initialLiquidity, "incorrect well token reserve");
        }
    }

    /// @dev getAddLiquidityOut: equal amounts.
    /// adding liquidity in equal proportions should summate and be
    /// scaled up by sqrt(ConstantProduct2.EXP_PRECISION)
    function test_getAddLiquidityOut_equalAmounts() public {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }
        uint lpAmountOut = well.getAddLiquidityOut(amounts);
        assertEq(lpAmountOut, 1000 * 1e24, "Incorrect AmountOut");
    }

    /// @dev addLiquidity: equal amounts.
    function test_addLiquidity_equalAmounts() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }
        uint lpAmountOut = 1000 * 1e24;

        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts, lpAmountOut, user);
        well.addLiquidity(amounts, lpAmountOut, user);

        Balances memory userBalance = getBalances(user, well);
        Balances memory wellBalance = getBalances(address(well), well);

        assertEq(userBalance.lp, lpAmountOut);

        // Consumes all of user's tokens
        assertEq(userBalance.tokens[0], 0, "incorrect token0 user amt");
        assertEq(userBalance.tokens[1], 0, "incorrect token1 user amt");

        // Adds to the Well's reserves
        assertEq(wellBalance.tokens[0], initialLiquidity + amounts[0], "incorrect token0 well amt");
        assertEq(wellBalance.tokens[1], initialLiquidity + amounts[1], "incorrect token1 well amt");
    }

    /// @dev getAddLiquidityOut: one-sided.
    function test_getAddLiquidityOut_oneToken() public {
        uint[] memory amounts = new uint[](2);
        amounts[0] = 10 * 1e18;
        amounts[1] = 0;

        uint amountOut = well.getAddLiquidityOut(amounts);
        assertEq(amountOut, 4_987_562_112_089_027_021_926_491, "incorrect amt out");
    }

    /// @dev addLiquidity: one-sided.
    function test_addLiquidity_oneToken() public prank(user) {
        uint[] memory amounts = new uint[](2);
        amounts[0] = 10 * 1e18;
        amounts[1] = 0;

        Snapshot memory before;
        AddLiquidityAction memory action;

        action.amounts = amounts;
        action.lpAmountOut = well.getAddLiquidityOut(amounts);
        action.recipient = user;
        action.fees = new uint[](2);

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidity(amounts, well.getAddLiquidityOut(amounts), user);

        afterAddLiquidity(before, action);
    }

    /// @dev addLiquidity: reverts for slippage
    function test_addLiquidity_revertIf_minAmountOutTooHigh() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }
        vm.expectRevert("Well: slippage");
        well.addLiquidity(amounts, 2001 * 1e27, user); // lpAmountOut is 2000*1e27
    }

    /// @dev addLiquidity -> removeLiquidity: zero hysteresis
    function test_addAndRemoveLiquidity() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }
        uint lpAmountOut = 1000 * 1e24;

        Snapshot memory before;
        AddLiquidityAction memory action;

        action.amounts = amounts;
        action.lpAmountOut = well.getAddLiquidityOut(amounts);
        action.recipient = user;
        action.fees = new uint[](2);

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidity(amounts, lpAmountOut, user);

        afterAddLiquidity(before, action);

        Snapshot memory beforeRemove;
        RemoveLiquidityAction memory actionRemove;

        actionRemove.lpAmountIn = well.getAddLiquidityOut(amounts);
        actionRemove.amounts = amounts;
        actionRemove.recipient = user;

        (beforeRemove, actionRemove) = beforeRemoveLiquidity(actionRemove);
        well.removeLiquidity(lpAmountOut, amounts, user);

        afterRemoveLiquidity(beforeRemove, actionRemove);
    }

    /// @dev addLiquidity: adding zero liquidity emits empty event but doesn't change reserves
    function test_addLiquidity_zeroChange() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);
        uint liquidity = 0;
        Snapshot memory before;
        AddLiquidityAction memory action;

        action.amounts = amounts;
        action.lpAmountOut = liquidity;
        action.recipient = user;
        action.fees = new uint[](2);

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidity(amounts, liquidity, user);

        afterAddLiquidity(before, action);
    }

    /// @dev addLiquidity: two-token fuzzed
    function testFuzz_addLiquidity(uint x, uint y) public prank(user) {
        // amounts to add as liquidity
        uint[] memory amounts = new uint[](2);
        amounts[0] = bound(x, 0, type(uint104).max);
        amounts[1] = bound(y, 0, type(uint104).max);
        mintTokens(user, amounts);

        Snapshot memory before;
        AddLiquidityAction memory action;

        action.amounts = amounts;
        action.lpAmountOut = well.getAddLiquidityOut(amounts);
        action.recipient = user;
        action.fees = new uint[](2);

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidity(amounts, well.getAddLiquidityOut(amounts), user);

        afterAddLiquidity(before, action);
    }
}
