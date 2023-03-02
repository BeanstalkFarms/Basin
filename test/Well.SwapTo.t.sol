// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20, Balances, Call, MockToken, Well} from "test/TestHelper.sol";
import {SwapHelper, SwapAction, SwapSnapshot} from "test/SwapHelper.sol";
import {MockFunctionBad} from "mocks/functions/MockFunctionBad.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {IWell} from "src/interfaces/IWell.sol";

contract WellSwapToTest is SwapHelper {

    function setUp() public {
        setupWell(2);
    }

    function test_getSwapIn() public {
        uint amountOut = 500 * 1e18;
        uint amountIn = well.getSwapIn(tokens[0], tokens[1], amountOut);
        assertEq(amountIn, 1000 * 1e18);
    }

    function testFuzz_getSwapIn_revertIf_insufficientWellBalance(uint i) public prank(user) {
        IERC20[] memory _tokens = well.tokens();
        Balances memory wellBalances = getBalances(address(well), well);
        vm.assume(i < _tokens.length);

        // Swap token `i` -> all other tokens
        for (uint j = 0; j < _tokens.length; ++j) {
            if (j != i) {
                // Request to buy more of {_tokens[j]} than the Well has.
                // There is no input amount that could complete this Swap.
                uint amountOut = wellBalances.tokens[j] + 1;
                vm.expectRevert(); // underflow
                well.getSwapIn(_tokens[i], _tokens[j], amountOut);
            }
        }
    }

    /// @dev Swaps should always revert if `fromToken` = `toToken`.
    function test_swapTo_revertIf_sameToken() public prank(user) {
        vm.expectRevert(IWell.InvalidTokens.selector);
        well.swapTo(tokens[0], tokens[0], 100 * 1e18, 0, user);
    }

    /// @dev Slippage revert occurs if maxAmountIn is too low
    function test_swapTo_revertIf_maxAmountInTooLow() public prank(user) {
        uint amountOut = 500 * 1e18;
        uint maxAmountIn = 999 * 1e18; // actual: 1000
        uint amountIn = 1000 * 1e18;

        vm.expectRevert(abi.encodeWithSelector(IWell.SlippageIn.selector, amountIn, maxAmountIn));
        well.swapTo(tokens[0], tokens[1], maxAmountIn, amountOut, user);
    }

    function testFuzz_swapTo(uint amountOut) public prank(user) {
        // User has 1000 of each token
        // Given current liquidity, swapping 1000 of one token gives 500 of the other
        uint maxAmountIn = 1000 * 1e18;
        amountOut = bound(amountOut, 0, 500 * 1e18);

        Balances memory userBalancesBefore = getBalances(user, well);
        Balances memory wellBalancesBefore = getBalances(address(well), well);

        // Decrease reserve of token 1 by `amountOut` which is paid to user
        // FIXME: refactor for N tokens
        uint[] memory calcBalances = new uint[](wellBalancesBefore.tokens.length);
        calcBalances[0] = wellBalancesBefore.tokens[0];
        calcBalances[1] = wellBalancesBefore.tokens[1] - amountOut;

        uint calcAmountIn = IWellFunction(wellFunction.target).calcReserve(
            calcBalances,
            0, // j
            wellBalancesBefore.lpSupply,
            wellFunction.data
        ) - wellBalancesBefore.tokens[0];

        vm.expectEmit(true, true, true, true);
        emit Swap(tokens[0], tokens[1], calcAmountIn, amountOut, user);
        well.swapTo(tokens[0], tokens[1], maxAmountIn, amountOut, user);

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
    }

    /// @dev Zero hysteresis: token0 -> token1 -> token0 gives the same result
    function testFuzz_swapTo_equalSwap(uint token0AmtOut) public prank(user) {
        // assume amtOut is lower due to slippage
        vm.assume(token0AmtOut < 500e18);
        uint token1In = well.swapTo(tokens[0], tokens[1], 1000e18, token0AmtOut, user);
        uint token0In = well.swapTo(tokens[1], tokens[0], 1000e18, token1In, user);
        assertEq(token0In, token0AmtOut);
    }
}
