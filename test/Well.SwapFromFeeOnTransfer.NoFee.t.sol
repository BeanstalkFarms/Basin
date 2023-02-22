// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, IERC20, Balances, Call, MockToken, Well, console} from "test/TestHelper.sol";
import {MockFunctionBad} from "mocks/functions/MockFunctionBad.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";

contract WellSwapFromFeeOnTransferNoFeeTest is TestHelper {
    Well badWell;

    event AddLiquidity(uint[] amounts);

    event Swap(IERC20 fromToken, IERC20 toToken, uint fromAmount, uint toAmount);

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

        Balances memory userBalanceBefore = getBalances(user, well);

        vm.expectEmit(true, true, true, true);
        emit Swap(tokens[0], tokens[1], amountIn, minAmountOut);

        uint amountOut = well.swapFromFeeOnTransfer(tokens[0], tokens[1], amountIn, minAmountOut, user);

        Balances memory userBalanceAfter = getBalances(user, well);
        Balances memory wellBalanceAfter = getBalances(address(well), well);

        assertEq(userBalanceBefore.tokens[0] - userBalanceAfter.tokens[0], amountIn, "incorrect token0 user amt");
        assertEq(userBalanceAfter.tokens[1] - userBalanceBefore.tokens[1], amountOut, "incorrect token1 user amt");

        assertEq(wellBalanceAfter.tokens[0], amountIn + initialLiquidity, "incorrect token0 well amt");
        assertEq(wellBalanceAfter.tokens[1], initialLiquidity - amountOut, "incorrect token1 well amt");
    }

    function testFuzz_swapFromFeeOnTransfer_noFee(uint amountIn) public prank(user) {
        amountIn = bound(amountIn, 0, 1000 * 1e18);
        Balances memory userBalanceBefore = getBalances(user, well);
        Balances memory wellBalanceBefore = getBalances(address(well), well);

        uint calcAmountOut = uint(well.getSwapOut(tokens[0], tokens[1], amountIn));

        vm.expectEmit(true, true, true, true);
        emit Swap(tokens[0], tokens[1], amountIn, calcAmountOut);

        uint amountOut = well.swapFromFeeOnTransfer(tokens[0], tokens[1], amountIn, 0, user);

        Balances memory userBalanceAfter = getBalances(user, well);
        Balances memory wellBalanceAfter = getBalances(address(well), well);

        assertEq(amountOut, calcAmountOut, "actual vs expected output");
        assertEq(userBalanceBefore.tokens[0] - userBalanceAfter.tokens[0], amountIn, "Incorrect token0 user balance");
        assertEq(
            userBalanceAfter.tokens[1] - userBalanceBefore.tokens[1], calcAmountOut, "Incorrect token1 user balance"
        );

        assertEq(wellBalanceAfter.tokens[0], wellBalanceBefore.tokens[0] + amountIn, "Incorrect token0 well reserve");
        assertEq(
            wellBalanceAfter.tokens[1], wellBalanceBefore.tokens[1] - calcAmountOut, "Incorrect token1 well reserve"
        );
    }

    //////////// EDGE CASE: IDENTICAL TOKENS ////////////

    /// @dev swapFromFeeOnTransfer: identical tokens results in no change in balances
    function testFuzz_swapFromFeeOnTransfer_sameToken_noFee(uint128 amountIn) public prank(user) {
        MockToken(address(tokens[0])).mint(user, amountIn);
        vm.expectRevert("Well: Invalid tokens");
        well.swapFromFeeOnTransfer(tokens[0], tokens[0], amountIn, 0, user);
    }
}
