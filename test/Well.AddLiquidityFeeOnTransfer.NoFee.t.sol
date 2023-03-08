// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {TestHelper, IERC20, Call, Balances} from "test/TestHelper.sol";
import {ConstantProduct2, IWellFunction} from "src/functions/ConstantProduct2.sol";
import {Snapshot, AddLiquidityAction, RemoveLiquidityAction, LiquidityHelper} from "test/LiquidityHelper.sol";

contract WellAddLiquidityFeeOnTransferNoFeeTest is LiquidityHelper {
    error SlippageOut(uint amountOut, uint minAmountOut);

    function setUp() public {
        setupWell(2);
    }

    /// @dev addLiquidity: equal amounts.
    function test_addLiquidity_equalAmounts_feeOnTransfer_noFee() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }

        uint lpAmountOut = well.getAddLiquidityOut(amounts);

        Snapshot memory before;
        AddLiquidityAction memory action;

        action.amounts = amounts;
        action.lpAmountOut = lpAmountOut;
        action.recipient = user;
        action.fees = new uint[](tokens.length);

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut, user);

        afterAddLiquidity(before, action);
    }

    /// @dev addLiquidity: one-sided.
    function test_addLiquidity_oneToken_feeOnTransfer_noFee() public prank(user) {
        uint[] memory amounts = new uint[](2);
        amounts[0] = 10 * 1e18;
        amounts[1] = 0;

        uint amountOut = 4_987_562_112_089_027_021_926_491;

        uint lpAmountOut = well.getAddLiquidityOut(amounts);

        Snapshot memory before;
        AddLiquidityAction memory action;

        action.amounts = amounts;
        action.lpAmountOut = lpAmountOut;
        action.recipient = user;
        action.fees = new uint[](tokens.length);

        assertEq(amountOut, lpAmountOut);
        (before, action) = beforeAddLiquidity(action);
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut, user);

        afterAddLiquidity(before, action);
    }

    /// @dev addLiquidity: reverts for slippage
    function test_addLiquidity_revertIf_minAmountOutTooHigh_feeOnTransfer_noFee() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }

        uint lpAmountOut = well.getAddLiquidityOut(amounts);
        vm.expectRevert(abi.encodeWithSelector(SlippageOut.selector, lpAmountOut, lpAmountOut + 1));
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut + 1, user); // lpAmountOut is 2000*1e27
    }

    /// @dev addLiquidity -> removeLiquidity: zero hysteresis
    function test_addAndRemoveLiquidity_feeOnTransfer_noFee() public prank(user) {
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
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut, user);

        afterAddLiquidity(before, action);

        Snapshot memory beforeRemove;
        RemoveLiquidityAction memory actionRemove;

        actionRemove.lpAmountIn = well.getAddLiquidityOut(amounts);
        actionRemove.amounts = amounts;
        actionRemove.recipient = user;
        actionRemove.fees = new uint[](2);

        (beforeRemove, actionRemove) = beforeRemoveLiquidity(actionRemove);
        well.removeLiquidity(lpAmountOut, amounts, user);

        afterRemoveLiquidity(beforeRemove, actionRemove);
    }

    /// @dev addLiquidity: adding zero liquidity emits empty event but doesn't change reserves
    function test_addLiquidity_zeroChange_feeOnTransfer_noFee() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);

        Snapshot memory before;
        AddLiquidityAction memory action;

        action.amounts = amounts;
        action.lpAmountOut = 0;
        action.recipient = user;
        action.fees = new uint[](2);

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidityFeeOnTransfer(amounts, 0, user);

        afterAddLiquidity(before, action);
    }

    /// @dev addLiquidity: two-token fuzzed
    function testFuzz_addLiquidity_feeOnTransfer_noFee(uint x, uint y) public prank(user) {
        // amounts to add as liquidity
        uint[] memory amounts = new uint[](2);
        amounts[0] = bound(x, 0, 1000e18);
        amounts[1] = bound(y, 0, 1000e18);

        Snapshot memory before;
        AddLiquidityAction memory action;
        uint lpAmountOut = well.getAddLiquidityOut(amounts);

        action.amounts = amounts;
        action.lpAmountOut = lpAmountOut;
        action.recipient = user;
        action.fees = new uint[](2);

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut, user);

        afterAddLiquidity(before, action);
    }
}
