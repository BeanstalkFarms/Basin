// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20, Balances, Call, MockToken, Well} from "test/TestHelper.sol";
import {SwapHelper, SwapAction} from "test/SwapHelper.sol";
import {MockFunctionBad} from "mocks/functions/MockFunctionBad.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {IWell} from "src/interfaces/IWell.sol";
import {IWellErrors} from "src/interfaces/IWellErrors.sol";

contract WellSwapToTest is SwapHelper {
    function setUp() public {
        setupWell(2);
    }

    function test_getSwapIn() public {
        uint256 amountOut = 500 * 1e18;
        uint256 amountIn = well.getSwapIn(tokens[0], tokens[1], amountOut);
        assertEq(amountIn, 1000 * 1e18);
    }

    function testFuzz_getSwapIn_revertIf_insufficientWellBalance(uint256 i) public prank(user) {
        IERC20[] memory _tokens = well.tokens();
        Balances memory wellBalances = getBalances(address(well), well);
        i = bound(i, 0, _tokens.length);

        // Swap token `i` -> all other tokens
        for (uint256 j; j < _tokens.length; ++j) {
            if (j != i) {
                // Request to buy more of {_tokens[j]} than the Well has.
                // There is no input amount that could complete this Swap.
                uint256 amountOut = wellBalances.tokens[j] + 1;
                vm.expectRevert(); // underflow
                well.getSwapIn(_tokens[i], _tokens[j], amountOut);
            }
        }
    }

    /// @dev Swaps should always revert if `fromToken` = `toToken`.
    function test_swapTo_revertIf_sameToken() public prank(user) {
        vm.expectRevert(IWellErrors.InvalidTokens.selector);
        well.swapTo(tokens[0], tokens[0], 100 * 1e18, 0, user, type(uint256).max);
    }

    /// @dev Slippage revert occurs if maxAmountIn is too low
    function test_swapTo_revertIf_maxAmountInTooLow() public prank(user) {
        uint256 amountOut = 500 * 1e18;
        uint256 maxAmountIn = 999 * 1e18; // actual: 1000
        uint256 amountIn = 1000 * 1e18;

        vm.expectRevert(abi.encodeWithSelector(IWellErrors.SlippageIn.selector, amountIn, maxAmountIn));
        well.swapTo(tokens[0], tokens[1], maxAmountIn, amountOut, user, type(uint256).max);
    }

    /// @dev Note: this covers the case where there is a fee as well
    function test_swapFromFeeOnTransferNoFee_revertIf_expired() public {
        vm.expectRevert(IWellErrors.Expired.selector);
        well.swapTo(tokens[0], tokens[1], 0, 0, user, block.timestamp - 1);
    }

    /// @dev tests assume 2 tokens in future we can extend for multiple tokens
    function testFuzz_swapTo(uint256 amountOut) public prank(user) {
        // User has 1000 of each token
        // Given current liquidity, swapping 1000 of one token gives 500 of the other
        uint256 maxAmountIn = 1000 * 1e18;
        amountOut = bound(amountOut, 0, 500 * 1e18);

        Balances memory userBalancesBefore = getBalances(user, well);
        Balances memory wellBalancesBefore = getBalances(address(well), well);

        // Decrease reserve of token 1 by `amountOut` which is paid to user
        uint256[] memory calcBalances = new uint256[](wellBalancesBefore.tokens.length);
        calcBalances[0] = wellBalancesBefore.tokens[0];
        calcBalances[1] = wellBalancesBefore.tokens[1] - amountOut;

        uint256 calcAmountIn = IWellFunction(wellFunction.target).calcReserve(
            calcBalances,
            0, // j
            wellBalancesBefore.lpSupply,
            wellFunction.data
        ) - wellBalancesBefore.tokens[0];

        vm.expectEmit(true, true, true, true);
        emit Swap(tokens[0], tokens[1], calcAmountIn, amountOut, user);
        well.swapTo(tokens[0], tokens[1], maxAmountIn, amountOut, user, type(uint256).max);

        Balances memory userBalancesAfter = getBalances(user, well);
        Balances memory wellBalancesAfter = getBalances(address(well), well);

        assertEq(
            userBalancesBefore.tokens[0] - userBalancesAfter.tokens[0], calcAmountIn, "Incorrect token0 user balance"
        );
        assertEq(userBalancesAfter.tokens[1] - userBalancesBefore.tokens[1], amountOut, "Incorrect token1 user balance");
        assertEq(
            wellBalancesAfter.tokens[0], wellBalancesBefore.tokens[0] + calcAmountIn, "Incorrect token0 well reserve"
        );
        assertEq(wellBalancesAfter.tokens[1], wellBalancesBefore.tokens[1] - amountOut, "Incorrect token1 well reserve");
        checkInvariant(address(well));
    }

    /// @dev Zero hysteresis: token0 -> token1 -> token0 gives the same result
    function testFuzz_swapTo_equalSwap(uint256 token0AmtOut) public prank(user) {
        // assume amtOut is lower due to slippage
        vm.assume(token0AmtOut < 500e18);
        uint256 token1In = well.swapTo(tokens[0], tokens[1], 1000e18, token0AmtOut, user, type(uint256).max);
        uint256 token0In = well.swapTo(tokens[1], tokens[0], 1000e18, token1In, user, type(uint256).max);
        assertEq(token0In, token0AmtOut);
        checkInvariant(address(well));
    }
}
