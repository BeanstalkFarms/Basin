// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {MockTokenFeeOnTransfer, TestHelper, IERC20, Call, Balances} from "test/TestHelper.sol";
import {ConstantProduct2, IWellFunction} from "src/functions/ConstantProduct2.sol";
import {Snapshot, AddLiquidityAction, RemoveLiquidityAction, LiquidityHelper} from "test/LiquidityHelper.sol";

contract WellAddLiquidityFeeOnTransferFeeTest is LiquidityHelper {
    error SlippageOut(uint amountOut, uint minAmountOut);

    function setUp() public {
        setupWell(deployWellFunction(), deployPumps(2), deployMockTokensFeeOnTransfer(2));
        MockTokenFeeOnTransfer(address(tokens[0])).setFee(1e16);
        MockTokenFeeOnTransfer(address(tokens[1])).setFee(1e16);
    }

    /// @dev addLiquidity: equal amounts.
    function test_addLiquidity_equalAmounts_feeOnTransfer_fee() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);
        uint[] memory feeAmounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
            feeAmounts[i] = amounts[i] * (1e18 - 1e16) / 1e18;
        }
        uint lpAmountOut = well.getAddLiquidityOut(feeAmounts);

        Snapshot memory before;
        AddLiquidityAction memory action;

        action.amounts = amounts;
        action.lpAmountOut = lpAmountOut;
        action.recipient = user;
        action.fees = feeAmounts;

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut, user);

        afterAddLiquidity(before, action);
    }

    /// @dev addLiquidity: one-sided.
    function test_addLiquidity_oneToken_feeOnTransfer_fee() public prank(user) {
        uint[] memory amounts = new uint[](2);
        amounts[0] = 10 * 1e18;
        amounts[1] = 0;
        uint[] memory feeAmounts = new uint[](2);
        feeAmounts[0] = amounts[0] * (1e18 - 1e16) / 1e18;
        feeAmounts[1] = 0;

        uint amountOut = 4_937_809_021_035_888_301_202_075;

        uint lpAmountOut = well.getAddLiquidityOut(feeAmounts);

        Snapshot memory before;
        AddLiquidityAction memory action;

        action.amounts = amounts;
        action.lpAmountOut = lpAmountOut;
        action.recipient = user;
        action.fees = feeAmounts;

        assertEq(amountOut, lpAmountOut);
        (before, action) = beforeAddLiquidity(action);
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut, user);

        afterAddLiquidity(before, action);
    }

    /// @dev addLiquidity: reverts for slippage
    function test_addLiquidity_revertIf_minAmountOutTooHigh_feeOnTransfer_fee() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }
        // expected amount is 1000 * 1e24, actual will be 990 * 1e24
        uint lpAmountOut = 990 * 1e24;
        
        vm.expectRevert(abi.encodeWithSelector(SlippageOut.selector, lpAmountOut, lpAmountOut + 1));
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut + 1, user); // 
    }

    /// @dev addLiquidity: adding zero liquidity emits empty event but doesn't change reserves
    function test_addLiquidity_zeroChange_feeOnTransfer_fee() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);

        Snapshot memory before;
        AddLiquidityAction memory action;

        action.amounts = amounts;
        action.lpAmountOut = 0;
        action.recipient = user;
        action.fees = new uint[](tokens.length);

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidityFeeOnTransfer(amounts, 0, user);

        afterAddLiquidity(before, action);
    }

    /// @dev addLiquidity: two-token fuzzed
    function testFuzz_addLiquidity_feeOnTransfer_fee(uint x, uint y) public prank(user) {
        // amounts to add as liquidity
        uint[] memory amounts = new uint[](2);
        amounts[0] = bound(x, 0, 1000e18);
        amounts[1] = bound(y, 0, 1000e18);

        uint[] memory feeAmounts = new uint[](2);
        feeAmounts[0] = amounts[0] - (amounts[0] * 1e16 / 1e18);
        feeAmounts[1] = amounts[1] - (amounts[1] * 1e16 / 1e18);

        Snapshot memory before;
        AddLiquidityAction memory action;
        uint lpAmountOut = well.getAddLiquidityOut(feeAmounts);

        action.amounts = amounts;
        action.lpAmountOut = lpAmountOut;
        action.recipient = user;
        action.fees = feeAmounts;

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut, user);

        afterAddLiquidity(before, action);
    }
}
