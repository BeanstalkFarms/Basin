// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {MockTokenFeeOnTransfer, TestHelper, IERC20, Balances, Call, MockToken, Well, console} from "test/TestHelper.sol";
import {MockFunctionBad} from "mocks/functions/MockFunctionBad.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";

contract WellSwapFromFeeOnTransferFeeTest is TestHelper {
    Well badWell;

    event AddLiquidity(uint[] amounts);

    event Swap(IERC20 fromToken, IERC20 toToken, uint fromAmount, uint toAmount);


    /// @dev tokens[0] has a fee, tokens[1] does not.
    function setUp() public {
        deployMockTokensFeeOnTransfer(1);
        setupWell(1);
        MockTokenFeeOnTransfer(address(tokens[0])).setFee(1e16);
    }

    //////////// SWAP FROM FEE ON TRANSFER (KNOWN AMOUNT IN -> UNKNOWN AMOUNT OUT) ////////////

    /// @dev swapFromFeeOnTransfer: slippage revert if minAmountOut is too high
    function test_swapFromFeeOnTransfer_revertIf_minAmountOutTooHigh_fee() public prank(user) {
        uint amountIn = 1000 * 1e18;
        uint minAmountOut = 500 * 1e18;
        vm.expectRevert("Well: slippage");
        well.swapFromFeeOnTransfer(tokens[0], tokens[1], amountIn, minAmountOut, user);
    }

    /**
     * @dev
     * 
     * tokens[0]: 1% fee
     * tokens[1]: No fee
     * 
     * Balance changes:
     *   User: 
     *      token0: (amountInToWell + fee) -> Well
     *      token1: (amountOutFromWell) <- Well
     *   Well:
     *      token0: (amountInToWell) <- User
     *      token1: (amountOutFromWell) -> User
     */
    function test_swapFromFeeOnTransfer_fee() public prank(user) {
        uint amountIn0 = 1000 * 1e18;
        _swapFrom_feeOnFromToken(amountIn0);
    }
    function testFuzz_swapFromFeeOnTransfer_fee(uint amountIn0) public prank(user) {
        amountIn0 = bound(amountIn0, 0, tokens[0].balanceOf(address(well)));
        _swapFrom_feeOnFromToken(amountIn0);
    }

    /**
     * @dev tokens[0]: 1% fee / tokens[1]: No fee
     * 
     * Resulting balance changes:
     *   User: 
     *      token0: Transfer (amountIn - fee) to Well
     *      token1: Receive  (amountOut)      from Well
     *   Well:
     *      token0: Receive  (amountIn - fee) from User
     *      token1: Transfer (amountOut)      to User
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
        emit Swap(tokens[0], tokens[1], amountInWithFee, calcAmountOut);
        uint amountOut = well.swapFromFeeOnTransfer(tokens[0], tokens[1], amountIn, 0, user);

        Balances memory userBalanceAfter = getBalances(user, well);
        Balances memory wellBalanceAfter = getBalances(address(well), well);
        
        // Since tokens[1] has no fee, our calculation should've been correct
        assertEq(amountOut, calcAmountOut, "actual vs expected output");

        // Compare balances
        assertEq(userBalanceBefore.tokens[0] - userBalanceAfter.tokens[0], amountIn, "Incorrect token0 user balance");
        assertEq(
            userBalanceAfter.tokens[1] - userBalanceBefore.tokens[1], calcAmountOut, "Incorrect token1 user balance"
        );
        assertEq(wellBalanceAfter.tokens[0], wellBalanceBefore.tokens[0] + amountInWithFee, "Incorrect token0 well reserve");
        assertEq(
            wellBalanceAfter.tokens[1], wellBalanceBefore.tokens[1] - calcAmountOut, "Incorrect token1 well reserve"
        );
    }
}
