// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {MockTokenFeeOnTransfer, TestHelper, IERC20, Balances, Call, MockToken, Well, console} from "test/TestHelper.sol";
import {SwapHelper, SwapAction, SwapSnapshot} from "test/SwapHelper.sol";
import {MockFunctionBad} from "mocks/functions/MockFunctionBad.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";

/**
 * @notice  
 */
contract WellSwapFromFeeOnTransferFeeTest is SwapHelper {
    function setUp() public {
        tokens = new IERC20[](2);
        tokens[0] = deployMockTokenFeeOnTransfer(0); // token[0] has fee
        tokens[1] = deployMockToken(1); // token[1] has no fee
        setupWell(2, deployWellFunction(), deployPumps(2), tokens); 
        MockTokenFeeOnTransfer(address(tokens[0])).setFee(1e16);
    }

    //////////// SWAP FROM FEE ON TRANSFER (KNOWN AMOUNT IN -> UNKNOWN AMOUNT OUT) ////////////

    /// @dev swapFromFeeOnTransfer: slippage revert if minAmountOut is too high
    /// since a fee is charged on amountIn, this should revert
    function test_swapFromFeeOnTransfer_revertIf_minAmountOutTooHigh_fee() public prank(user) {
        uint amountIn = 1000 * 1e18;
        uint minAmountOut = 500 * 1e18;
        vm.expectRevert("Well: slippage");
        well.swapFromFeeOnTransfer(tokens[0], tokens[1], amountIn, minAmountOut, user);
    }

    ////////// Fee on `fromToken` only

    function test_swapFromFeeOnTransfer_fromToken() public prank(user) {
        uint amountIn0 = 1000 * 1e18;
        _swapFrom_feeOnFromToken(amountIn0);
    }
    function testFuzz_swapFromFeeOnTransfer_fromToken(uint amountIn0) public prank(user) {
        amountIn0 = bound(amountIn0, 0, tokens[0].balanceOf(address(well)));
        _swapFrom_feeOnFromToken(amountIn0);
    }

    /**
     * @dev tokens[0]: 1% fee / tokens[1]: No fee
     * 
     * Swapping from tokens[0] -> tokens[1]
     * 
     * Resulting balance changes:
     *   User: 
     *      token0: Transfer (amountIn) to Well
     *      token1: Receive (amountOut) from Well
     *   Well:
     *      token0: Receive (amountIn - fee) from User
     *      token1: Transfer (amountOut) to User
     */
    function _swapFrom_feeOnFromToken(uint amountIn) internal {
        Balances memory userBalanceBefore = getBalances(user, well);
        Balances memory wellBalanceBefore = getBalances(address(well), well);

        // Fee on input
        uint _fee = amountIn * MockTokenFeeOnTransfer(address(tokens[0])).fee() / 1e18;
        uint amountInWithFee = amountIn - _fee;

        // Reduce the amountIn by fee to get expected amount out
        uint calcAmountOut = well.getSwapOut(tokens[0], tokens[1], amountInWithFee);
        
        // Perform swap
        vm.expectEmit(true, true, true, true);
        emit Swap(tokens[0], tokens[1], amountInWithFee, calcAmountOut, user);
        uint amountOut = well.swapFromFeeOnTransfer(tokens[0], tokens[1], amountIn, calcAmountOut, user);

        Balances memory userBalanceAfter = getBalances(user, well);
        Balances memory wellBalanceAfter = getBalances(address(well), well);
        
        // Since tokens[1] has no fee, our calculation should've been correct
        assertEq(amountOut, calcAmountOut, "actual vs expected output");

        // Fee taken on tokens[0]
        assertEq(userBalanceBefore.tokens[0] - userBalanceAfter.tokens[0], amountIn, "Incorrect token0 user balance");
        assertEq(wellBalanceAfter.tokens[0], wellBalanceBefore.tokens[0] + amountInWithFee, "Incorrect token0 well reserve");

        // No fee taken on tokens[1]
        assertEq(
            userBalanceAfter.tokens[1] - userBalanceBefore.tokens[1], calcAmountOut, "Incorrect token1 user balance"
        );
        assertEq(
            wellBalanceAfter.tokens[1], wellBalanceBefore.tokens[1] - calcAmountOut, "Incorrect token1 well reserve"
        );
    }

    ////////// Fee on `toToken` only

    /**
     * @dev tokens[0]: 1% fee / tokens[1]: No fee
     * 
     * Swapping from tokens[1] -> tokens[0]
     * 
     * Resulting balance changes:
     *   User: 
     *      token0: Transfer (amountIn) to Well
     *      token1: Receive (amountOut - fee) from Well
     *   Well:
     *      token0: Receive (amountIn) from User
     *      token1: Transfer (amountOut) to User
     * 
     * NOTE: Since the fee is incurred after `amountOut` is calculated in the Well,
     * the Swap event contains the amount deducted from the Well, not the amount
     * given to the User.
     */
    function testFuzz_swapFromFeeOnTransfer_toToken(uint amountIn) public prank(user) {
        amountIn = bound(amountIn, 0, tokens[1].balanceOf(address(well)));
        SwapSnapshot memory bef;
        SwapAction memory act;
        
        // Setup delta
        act.userSpends = amountIn;
        act.wellReceives = amountIn;
        act.wellSends = well.getSwapOut(tokens[1], tokens[0], amountIn);
        uint _fee = act.wellSends * MockTokenFeeOnTransfer(address(tokens[0])).fee() / 1e18;
        act.userReceives = act.wellSends - _fee;

        (bef, act) = beforeSwapFrom(1, 0, user, act);

        // Perform swap; returns the amount that the Well sent NOT including the transfer fee
        uint amountOut = well.swapFromFeeOnTransfer(tokens[1], tokens[0], amountIn, act.userReceives, user);

        assertEq(amountOut, act.wellSends, "amountOut different than calculated");
        afterSwapFrom(1, 0, bef, act);
    }
}
