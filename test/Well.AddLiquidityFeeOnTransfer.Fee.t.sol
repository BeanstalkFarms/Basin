// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {MockTokenFeeOnTransfer, TestHelper, IERC20, Call, Balances} from "test/TestHelper.sol";
import {ConstantProduct2, IWellFunction} from "src/functions/ConstantProduct2.sol";
import {Snapshot, AddLiquidityAction, RemoveLiquidityAction, LiquidityHelper} from "test/LiquidityHelper.sol";

contract WellAddLiquidityFeeOnTransferWithFeeTest is LiquidityHelper {
    function setUp() public {
        setupWell(deployWellFunction(), deployPumps(2), deployMockTokensFeeOnTransfer(2));
        MockTokenFeeOnTransfer(address(tokens[0])).setFee(1e16);
        MockTokenFeeOnTransfer(address(tokens[1])).setFee(1e16);
    }

    function test_addLiquidityFeeOnTransferWithFee_revertIf_minAmountOutTooHigh() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }

        // expected amount is 1000 * 1e24, actual will be 990 * 1e24
        uint lpAmountOut = 990 * 1e24;
        
        vm.expectRevert(abi.encodeWithSelector(SlippageOut.selector, lpAmountOut, lpAmountOut + 1));
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut + 1, user, type(uint).max);
    }

    function test_addLiquidityFeeOnTransferWithFee_revertIf_expired() public {
        vm.expectRevert(Expired.selector);
        well.addLiquidityFeeOnTransfer(new uint[](tokens.length), 0, user, block.timestamp - 1);
    }

    function test_addLiquidityFeeOnTransferWithFee_equalAmounts() public prank(user) {
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
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut, user, type(uint).max);
        afterAddLiquidity(before, action);
    }

    function test_addLiquidityFeeOnTransferWithFee_oneToken() public prank(user) {
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
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut, user, type(uint).max);
        afterAddLiquidity(before, action);
    }

    /// @dev Adding zero liquidity emits empty event but doesn't change reserves
    function test_addLiquidityFeeOnTransferWithFee_zeroChange() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);

        Snapshot memory before;
        AddLiquidityAction memory action;

        action.amounts = amounts;
        action.lpAmountOut = 0;
        action.recipient = user;
        action.fees = new uint[](tokens.length);

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidityFeeOnTransfer(amounts, 0, user, type(uint).max);
        afterAddLiquidity(before, action);
    }

    /// @dev Two-token fuzz test adding liquidity in any ratio
    function testFuzz_addLiquidityFeeOnTransferWithFee(uint x, uint y) public prank(user) {
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
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut, user, type(uint).max);
        afterAddLiquidity(before, action);
    }
}
