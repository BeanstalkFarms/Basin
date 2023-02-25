// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20, Balances, Call, MockToken, Well, console} from "test/TestHelper.sol";
import {SwapHelper, SwapAction, SwapSnapshot} from "test/SwapHelper.sol";
import {MockFunctionBad} from "mocks/functions/MockFunctionBad.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";

contract WellSwapTest is SwapHelper {
    Well badWell;

    function setUp() public {
        setupWell(2);
    }

    //////////// SWAP FROM (KNOWN AMOUNT IN -> UNKNOWN AMOUNT OUT) ////////////

    function test_getSwapOut() public {
        uint amountIn = 1000 * 1e18;
        uint amountOut = well.getSwapOut(tokens[0], tokens[1], amountIn);

        assertEq(amountOut, 500 * 1e18);
    }

    function testFuzz_getSwapOut_revertIf_insufficientWellBalance(uint amountIn, uint i) public prank(user) {
        // swap token `i` -> all other tokens
        vm.assume(i < tokens.length);

        // find an input amount that produces an output amount higher than what the Well has.
        // When the Well is deployed it has zero reserves, so any nonzero value should revert.
        amountIn = bound(amountIn, 1, type(uint128).max);

        // Deploy a new Well with a poorly engineered pricing function.
        // Its `getBalance` function can return an amount greater than the Well holds.
        IWellFunction badFunction = new MockFunctionBad();
        badWell = encodeAndBoreWell(
            address(aquifer), wellImplementation, tokens, Call(address(badFunction), ""), pumps, bytes32(0)
        );

        // check assumption that reserves are empty
        Balances memory wellBalances = getBalances(address(badWell), badWell);
        assertEq(wellBalances.tokens[0], 0, "bad assumption: wellBalances.tokens[0] != 0");
        assertEq(wellBalances.tokens[1], 0, "bad assumption: wellBalances.tokens[1] != 0");

        for (uint j = 0; j < tokens.length; ++j) {
            if (j != i) {
                vm.expectRevert();
                badWell.getSwapOut(tokens[i], tokens[j], amountIn);
            }
        }
    }

    function test_swapFrom_revertIf_sameToken() public prank(user) {
        vm.expectRevert("Well: Invalid tokens");
        well.swapFrom(tokens[0], tokens[0], 100 * 1e18, 0, user);
    }

    /// @dev swapFrom: slippage revert if minAmountOut is too high
    function test_swapFrom_revertIf_minAmountOutTooHigh() public prank(user) {
        uint amountIn = 1000 * 1e18;
        uint minAmountOut = 501 * 1e18; // actual: 500

        vm.expectRevert("Well: slippage");
        well.swapFrom(tokens[0], tokens[1], amountIn, minAmountOut, user);
    }

    function testFuzz_swapFrom(uint amountIn) public prank(user) {
        amountIn = bound(amountIn, 0, tokens[0].balanceOf(user));
        
        (SwapSnapshot memory bef, SwapAction memory act) = beforeSwapFrom(0, 1, amountIn, user);
        act.wellSends = well.swapFrom(tokens[0], tokens[1], amountIn, 0, user);
        afterSwapFrom(0, 1, bef, act);
    }

    /// @dev Zero hysteresis: token0 -> token1 -> token0 gives the same result
    function testFuzz_swapFrom_equalSwap(uint token0AmtIn) public prank(user) {
        vm.assume(token0AmtIn < tokens[0].balanceOf(user));
        uint token1Out = well.swapFrom(tokens[0], tokens[1], token0AmtIn, 0, user);
        uint token0Out = well.swapFrom(tokens[1], tokens[0], token1Out, 0, user);
        assertEq(token0Out, token0AmtIn);
    }

    //////////// SWAP TO (UNKNOWN AMOUNT IN -> KNOWN AMOUNT OUT) ////////////

    function test_getSwapIn() public {
        uint amountOut = 500 * 1e18;
        uint amountIn = well.getSwapIn(tokens[0], tokens[1], amountOut);
        assertEq(amountIn, 1000 * 1e18);
    }

    function testFuzz_getSwapIn_revertIf_insufficientWellBalance(uint amountOut, uint i) public prank(user) {
        IERC20[] memory _tokens = well.tokens();
        Balances memory wellBalances = getBalances(address(well), well);
        vm.assume(i < _tokens.length);

        // request more than the Well has. there is no input amount that could do this.
        amountOut = bound(amountOut, wellBalances.tokens[i] + 1, type(uint128).max);

        // swap token `i` -> all other tokens
        for (uint j = 0; j < _tokens.length; ++j) {
            if (j != i) {
                vm.expectRevert(); // underflow
                well.getSwapIn(_tokens[i], _tokens[j], amountOut);
            }
        }
    }

    function test_swapTo_revertIf_sameToken() public prank(user) {
        vm.expectRevert("Well: Invalid tokens");
        well.swapTo(tokens[0], tokens[0], 100 * 1e18, 0, user);
    }

    /// @dev swapTo: slippage revert occurs if maxAmountIn is too low
    function test_swapTo_revertIf_maxAmountInTooLow() public prank(user) {
        uint amountOut = 500 * 1e18;
        uint maxAmountIn = 999 * 1e18; // actual: 1000
        vm.expectRevert("Well: slippage");
        well.swapTo(tokens[0], tokens[1], maxAmountIn, amountOut, user);
    }

    function testFuzz_swapTo(uint amountOut) public prank(user) {
        // user has 1000 of each token
        // given current liquidity, swapping 1000 of one token gives 500 of the other
        uint maxAmountIn = 1000 * 1e18;
        amountOut = bound(amountOut, 0, 500 * 1e18);

        Balances memory userBalancesBefore = getBalances(user, well);
        Balances memory wellBalancesBefore = getBalances(address(well), well);

        // Decrease reserve of token 1 by `amountOut` which is paid to user
        // FIXME: refactor for N tokens
        uint[] memory calcBalances = new uint[](wellBalancesBefore.tokens.length);
        calcBalances[0] = wellBalancesBefore.tokens[0];
        calcBalances[1] = wellBalancesBefore.tokens[1] - amountOut;

        console.log(calcBalances[1], wellBalancesBefore.tokens[1]);

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
