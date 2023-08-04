// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TestHelper, IERC20, Balances, Call, MockToken, Well} from "test/TestHelper.sol";
import {SwapHelper, SwapAction, Snapshot} from "test/SwapHelper.sol";
import {MockFunctionBad} from "mocks/functions/MockFunctionBad.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {IWell} from "src/interfaces/IWell.sol";
import {IWellErrors} from "src/interfaces/IWellErrors.sol";

/**
 * @dev Tests {swapFromFeeOnTransfer} when tokens involved in the swap DO NOT
 * incur a fee on transfer.
 */
contract WellSwapFromFeeOnTransferNoFeeTest is SwapHelper {
    function setUp() public {
        setupWell(2);
    }

    /// @dev Slippage revert if minAmountOut is too high.
    function test_swapFromFeeOnTransferNoFee_revertIf_minAmountOutTooHigh() public prank(user) {
        uint256 amountIn = 1000 * 1e18;
        uint256 minAmountOut = 501 * 1e18; // actual: 500
        uint256 amountOut = 500 * 1e18;

        vm.expectRevert(abi.encodeWithSelector(IWellErrors.SlippageOut.selector, amountOut, minAmountOut));
        well.swapFromFeeOnTransfer(tokens[0], tokens[1], amountIn, minAmountOut, user, type(uint256).max);
    }

    /// @dev Swaps should always revert if `fromToken` = `toToken`.
    function testFuzz_swapFromFeeOnTransferNoFee_revertIf_sameToken(uint128 amountIn) public prank(user) {
        MockToken(address(tokens[0])).mint(user, amountIn);

        vm.expectRevert(IWellErrors.InvalidTokens.selector);
        well.swapFromFeeOnTransfer(tokens[0], tokens[0], amountIn, 0, user, type(uint256).max);
    }

    /// @dev Note: this covers the case where there is a fee as well
    function test_swapFromFeeOnTransferNoFee_revertIf_expired() public {
        vm.expectRevert(IWellErrors.Expired.selector);
        well.swapFromFeeOnTransfer(tokens[0], tokens[1], 0, 0, user, block.timestamp - 1);
    }

    /// @dev With no fees, behavior is identical to {swapFrom}.
    function testFuzz_swapFromFeeOnTransfer_noFee(uint256 amountIn) public prank(user) {
        amountIn = bound(amountIn, 0, tokens[0].balanceOf(user));

        (Snapshot memory bef, SwapAction memory act) = beforeSwapFrom(0, 1, amountIn);
        well.swapFromFeeOnTransfer(tokens[0], tokens[1], amountIn, act.userReceives, user, type(uint256).max);
        afterSwapFrom(bef, act);
    }
}
