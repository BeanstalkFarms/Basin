// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, IERC20, Balances, Call, MockToken, Well, console} from "test/TestHelper.sol";
import {SwapHelper, BeforeSwap} from "test/SwapHelper.sol";
import {MockFunctionBad} from "mocks/functions/MockFunctionBad.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";

contract WellSwapFromFeeOnTransferNoFeeTest is SwapHelper {
    Well badWell;

    function setUp() public {
        setupWell(2);
    }

    //////////// SWAP FROM FEE ON TRANSFER (KNOWN AMOUNT IN -> UNKNOWN AMOUNT OUT) ////////////

    /// @dev swapFromFeeOnTransfer: slippage revert if minAmountOut is too high
    function test_swapFromFeeOnTransfer_revertIf_minAmountOutTooHigh_noFee() public prank(user) {
        uint amountIn = 1000 * 1e18;
        uint minAmountOut = 501 * 1e18; // actual: 500
        
        vm.expectRevert("Well: slippage");
        well.swapFromFeeOnTransfer(tokens[0], tokens[1], amountIn, minAmountOut, user);
    }

    function test_swapFromFeeOnTransfer_noFee() public prank(user) {
        uint amountIn = 1000 * 1e18;
        uint minAmountOut = 500 * 1e18;

        BeforeSwap memory b = _before_swapFrom(0, 1, amountIn, user);
        uint amountOut = well.swapFromFeeOnTransfer(tokens[0], tokens[1], amountIn, minAmountOut, user);
        _after_swapFrom(0, 1, amountOut, b);
    }

    function testFuzz_swapFromFeeOnTransfer_noFee(uint amountIn) public prank(user) {
        amountIn = bound(amountIn, 0, tokens[0].balanceOf(user));
        
        BeforeSwap memory b = _before_swapFrom(0, 1, amountIn, user);
        uint amountOut = well.swapFromFeeOnTransfer(tokens[0], tokens[1], amountIn, b.calcAmountOut, user);
        _after_swapFrom(0, 1, amountOut, b);
    }

    //////////// EDGE CASE: IDENTICAL TOKENS ////////////

    /// @dev swapFromFeeOnTransfer: identical tokens results in no change in balances
    function testFuzz_swapFromFeeOnTransfer_sameToken_noFee(uint128 amountIn) public prank(user) {
        MockToken(address(tokens[0])).mint(user, amountIn);

        vm.expectRevert("Well: Invalid tokens");
        well.swapFromFeeOnTransfer(tokens[0], tokens[0], amountIn, 0, user);
    }
}
