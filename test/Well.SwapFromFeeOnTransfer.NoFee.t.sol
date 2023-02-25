// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, IERC20, Balances, Call, MockToken, Well, console} from "test/TestHelper.sol";
import {SwapHelper, SwapAction, SwapSnapshot} from "test/SwapHelper.sol";
import {MockFunctionBad} from "mocks/functions/MockFunctionBad.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";

contract WellSwapFromFeeOnTransferNoFeeTest is SwapHelper {
    Well badWell;

    function setUp() public {
        setupWell(2);
    }

    //////////// SWAP FROM FEE ON TRANSFER (KNOWN AMOUNT IN -> UNKNOWN AMOUNT OUT) ////////////

    /// @dev swapFromFeeOnTransfer: slippage revert if minAmountOut is too high
    function test_swapFromFeeOnTransfer_noFee_revertIf_minAmountOutTooHigh() public prank(user) {
        uint amountIn = 1000 * 1e18;
        uint minAmountOut = 501 * 1e18; // actual: 500

        vm.expectRevert("Well: slippage");
        well.swapFromFeeOnTransfer(tokens[0], tokens[1], amountIn, minAmountOut, user);
    }

    function testFuzz_swapFromFeeOnTransfer_noFee_revertIf_sameToken(uint128 amountIn) public prank(user) {
        MockToken(address(tokens[0])).mint(user, amountIn);

        vm.expectRevert("Well: Invalid tokens");
        well.swapFromFeeOnTransfer(tokens[0], tokens[0], amountIn, 0, user);
    }

    function testFuzz_swapFromFeeOnTransfer_noFee(uint amountIn) public prank(user) {
        amountIn = bound(amountIn, 0, tokens[0].balanceOf(user));

        (SwapSnapshot memory bef, SwapAction memory act) = beforeSwapFrom(0, 1, amountIn);
        well.swapFromFeeOnTransfer(tokens[0], tokens[1], amountIn, act.userReceives, user);
        afterSwapFrom(bef, act);
    }
}
