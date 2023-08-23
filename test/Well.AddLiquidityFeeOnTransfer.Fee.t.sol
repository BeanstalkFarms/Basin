// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {MockTokenFeeOnTransfer, TestHelper, IERC20, Call, Balances} from "test/TestHelper.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";
import {Snapshot, AddLiquidityAction, RemoveLiquidityAction, LiquidityHelper} from "test/LiquidityHelper.sol";

contract WellAddLiquidityFeeOnTransferWithFeeTest is LiquidityHelper {
    function setUp() public {
        setupWell(deployWellFunction(), deployPumps(2), deployMockTokensFeeOnTransfer(2));
        MockTokenFeeOnTransfer(address(tokens[0])).setFee(1e16);
        MockTokenFeeOnTransfer(address(tokens[1])).setFee(1e16);
    }

    function test_addLiquidityFeeOnTransferWithFee_revertIf_minAmountOutTooHigh() public prank(user) {
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }

        // expected amount is 1000 * 1e24, actual will be 990 * 1e24
        uint256 lpAmountOut = 990 * 1e24;

        vm.expectRevert(abi.encodeWithSelector(SlippageOut.selector, lpAmountOut, lpAmountOut + 1));
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut + 1, user, type(uint256).max);
    }

    function test_addLiquidityFeeOnTransferWithFee_revertIf_expired() public {
        vm.expectRevert(Expired.selector);
        well.addLiquidityFeeOnTransfer(new uint256[](tokens.length), 0, user, block.timestamp - 1);
    }

    function test_addLiquidityFeeOnTransferWithFee_equalAmounts() public prank(user) {
        uint256[] memory amounts = new uint256[](tokens.length);
        uint256[] memory feeAmounts = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
            feeAmounts[i] = amounts[i] * (1e18 - 1e16) / 1e18;
        }
        uint256 lpAmountOut = well.getAddLiquidityOut(feeAmounts);

        Snapshot memory before;
        AddLiquidityAction memory action;
        action.amounts = amounts;
        action.lpAmountOut = lpAmountOut;
        action.recipient = user;
        action.fees = feeAmounts;

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut, user, type(uint256).max);
        afterAddLiquidity(before, action);
    }

    function test_addLiquidityFeeOnTransferWithFee_oneToken() public prank(user) {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10 * 1e18;
        amounts[1] = 0;

        uint256[] memory feeAmounts = new uint256[](2);
        feeAmounts[0] = amounts[0] * (1e18 - 1e16) / 1e18;
        feeAmounts[1] = 0;

        uint256 amountOut = 4_937_809_021_035_888_301_202_075;
        uint256 lpAmountOut = well.getAddLiquidityOut(feeAmounts);

        Snapshot memory before;
        AddLiquidityAction memory action;
        action.amounts = amounts;
        action.lpAmountOut = lpAmountOut;
        action.recipient = user;
        action.fees = feeAmounts;

        assertEq(amountOut, lpAmountOut);

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut, user, type(uint256).max);
        afterAddLiquidity(before, action);
    }

    /// @dev Adding zero liquidity emits empty event but doesn't change reserves
    function test_addLiquidityFeeOnTransferWithFee_zeroChange() public prank(user) {
        uint256[] memory amounts = new uint256[](tokens.length);

        Snapshot memory before;
        AddLiquidityAction memory action;

        action.amounts = amounts;
        action.lpAmountOut = 0;
        action.recipient = user;
        action.fees = new uint256[](tokens.length);

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidityFeeOnTransfer(amounts, 0, user, type(uint256).max);
        afterAddLiquidity(before, action);
    }

    /// @dev Two-token fuzz test adding liquidity in any ratio
    function testFuzz_addLiquidityFeeOnTransferWithFee(uint256 x, uint256 y) public prank(user) {
        // amounts to add as liquidity
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = bound(x, 0, 1000e18);
        amounts[1] = bound(y, 0, 1000e18);

        uint256[] memory feeAmounts = new uint256[](2);
        feeAmounts[0] = amounts[0] - (amounts[0] * 1e16 / 1e18);
        feeAmounts[1] = amounts[1] - (amounts[1] * 1e16 / 1e18);

        Snapshot memory before;
        AddLiquidityAction memory action;
        uint256 lpAmountOut = well.getAddLiquidityOut(feeAmounts);
        action.amounts = amounts;
        action.lpAmountOut = lpAmountOut;
        action.recipient = user;
        action.fees = feeAmounts;

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut, user, type(uint256).max);
        afterAddLiquidity(before, action);
    }
}
