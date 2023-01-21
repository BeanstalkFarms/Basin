/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";
import {MockFunctionBad} from "mocks/functions/MockFunctionBad.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";

contract WellSwapTest is TestHelper {

    event AddLiquidity(uint[] amounts);

    event Swap(IERC20 fromToken, IERC20 toToken, uint fromAmount, uint toAmount);

    function setUp() public {
        setupWell(2);
    }

    //////////// SWAP FROM (KNOWN AMOUNT IN -> UNKNOWN AMOUNT OUT) ////////////

    function test_getSwapOut() public {
        uint amountIn = 1000 * 1e18;
        uint amountOut = well.getSwapOut(tokens[0], tokens[1], amountIn);
        assertEq(amountOut, 500 * 1e18);
    }

    /// @dev swapFrom: slippage revert if minAmountOut is too high
    function test_swapFrom_revertIf_minAmountOutTooHigh() prank(user) public {
        uint amountIn = 1000 * 1e18;
        uint minAmountOut = 501 * 1e18; // actual: 500
        vm.expectRevert("Well: slippage");
        well.swapFrom(tokens[0], tokens[1], amountIn, minAmountOut, user);
    }

    function test_swapFrom() prank(user) public {
        uint amountIn = 1000 * 1e18;
        uint minAmountOut = 500 * 1e18;

        uint balanceBefore0 = tokens[0].balanceOf(user);
        uint balanceBefore1 = tokens[1].balanceOf(user);

        vm.expectEmit(true, true, true, true);
        emit Swap(tokens[0], tokens[1], amountIn, minAmountOut);

        uint amountOut = well.swapFrom(tokens[0], tokens[1], amountIn, minAmountOut, user);

        assertEq(balanceBefore0 - tokens[0].balanceOf(user), amountIn, "incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user) - balanceBefore1, amountOut, "incorrect token1 user amt");

        assertEq(tokens[0].balanceOf(address(well)), 2000 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 500 * 1e18, "incorrect token0 well amt");
    }

    function testFuzz_swapFrom(uint amountIn) prank(user) public {
        amountIn = bound(amountIn, 0, 1000 * 1e18); 
        uint balanceBefore0 = tokens[0].balanceOf(user);
        uint balanceBefore1 = tokens[1].balanceOf(user);
        uint[] memory wellBalances = new uint[](2);
        wellBalances[0] = tokens[0].balanceOf(address(well));
        wellBalances[1] = tokens[1].balanceOf(address(well));

        uint calcAmountOut = uint256(well.getSwap(tokens[0], tokens[1], int(amountIn)));

        vm.expectEmit(true, true, true, true);
        emit Swap(tokens[0], tokens[1], amountIn, calcAmountOut);

        uint amountOut = well.swapFrom(tokens[0], tokens[1], amountIn, 0, user);

        assertEq(amountOut,calcAmountOut, "actual vs expected output");
        assertEq(balanceBefore0 - tokens[0].balanceOf(user), amountIn, "Incorrect token0 user balance");
        assertEq(tokens[1].balanceOf(user) - balanceBefore1, calcAmountOut, "Incorrect token1 user balance");

        assertEq(tokens[0].balanceOf(address(well)), wellBalances[0] + amountIn, "Incorrect token0 well balance");
        assertEq(tokens[1].balanceOf(address(well)), wellBalances[1] - calcAmountOut, "Incorrect token1 well balance");
    }

    //////////// SWAP TO (UNKNOWN AMOUNT IN -> KNOWN AMOUNT OUT) ////////////

    function test_getSwapIn() public {
        uint amountOut = 500 * 1e18;
        uint amountIn = well.getSwapIn(tokens[0], tokens[1], amountOut);
        assertEq(amountIn, 1000 * 1e18);
    }

    /// @dev swapTo: slippage revert occurs if maxAmountIn is too low
    function test_swapTo_revertIf_maxAmountInTooLow() prank(user) public {
        uint amountOut = 500 * 1e18;
        uint maxAmountIn = 999 * 1e18; // actual: 1000
        vm.expectRevert("Well: slippage");
        well.swapTo(tokens[0], tokens[1], maxAmountIn, amountOut, user);
    }

    function test_swapTo() prank(user) public {
        uint amountOut = 500 * 1e18;
        uint maxAmountIn = 1000 * 1e18;

        vm.expectEmit(true, true, true, true);
        emit Swap(tokens[0], tokens[1], maxAmountIn, amountOut);

        uint balanceBefore0 = tokens[0].balanceOf(user);
        uint balanceBefore1 = tokens[1].balanceOf(user);

        uint amountIn = well.swapTo(tokens[0], tokens[1], maxAmountIn, amountOut, user);

        assertEq(balanceBefore0 - tokens[0].balanceOf(user), amountIn, "incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user) - balanceBefore1, amountOut, "incorrect token1 user amt");

        assertEq(tokens[0].balanceOf(address(well)), 2000 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 500 * 1e18, "incorrect token1 well amt");
    }

    function testFuzz_swapTo(uint amountOut) prank(user) public {
        // user has 1000 of each token
        // given current liquidity, swapping 1000 of one token gives 500 of the other
        uint maxAmountIn = 1000 * 1e18;
        amountOut = bound(amountOut, 0, 500 * 1e18);

        uint balanceBefore0 = tokens[0].balanceOf(user);
        uint balanceBefore1 = tokens[1].balanceOf(user);
        uint[] memory wellBalances = new uint[](2);
        wellBalances[0] = tokens[0].balanceOf(address(well));
        wellBalances[1] = tokens[1].balanceOf(address(well));

        uint calcAmountIn = uint256(-well.getSwap(tokens[1], tokens[0], -int(amountOut)));

        vm.expectEmit(true, true, true, true);
        emit Swap(tokens[0], tokens[1], calcAmountIn, amountOut);

        well.swapTo(tokens[0], tokens[1], maxAmountIn, amountOut, user);

        assertEq(balanceBefore0 - tokens[0].balanceOf(user), calcAmountIn, "Incorrect token0 user balance");
        assertEq(tokens[1].balanceOf(user) - balanceBefore1, amountOut, "Incorrect token1 user balance");

        assertEq(tokens[0].balanceOf(address(well)), wellBalances[0] + calcAmountIn, "Incorrect token0 well balance");
        assertEq(tokens[1].balanceOf(address(well)), wellBalances[1] - amountOut, "Incorrect token1 well balance");
    }

    //////////// EDGE CASE: IDENTICAL TOKENS ////////////

    /// @dev swapFrom: identical tokens results in no change in balances
    function testFuzz_swapFrom_sameToken(uint amountIn) 
        prank(user)
        check_noTokenBalanceChange() 
        public 
    {
        vm.assume(amountIn > 0);
        vm.assume(amountIn <= tokens[0].balanceOf(user));
        well.swapFrom(tokens[0], tokens[0], amountIn, 0, user);
        assertEq(well.getSwapOut(tokens[0], tokens[0], amountIn), amountIn, "getSwapOut mismatch");
        assertEq(well.getSwap(tokens[0], tokens[0], int(amountIn)), int(amountIn), "getSwap mismatch");
    }

    /// @dev swapTo: identical tokens results in no change in balances
    function testFuzz_swapTo_sameToken(uint amountOut)
        prank(user)
        check_noTokenBalanceChange() 
        public
    {
        vm.assume(amountOut > 0);
        vm.assume(amountOut <= tokens[0].balanceOf(user));
        well.swapTo(tokens[0], tokens[0], 100e6, 0, user);
        assertEq(well.getSwapIn(tokens[0], tokens[0], amountOut), amountOut, "getSwapIn mismatch");
        assertEq(well.getSwap(tokens[0], tokens[0], int(amountOut)), int(amountOut), "getSwap mismatch");
    }

    modifier check_noTokenBalanceChange() {
        Balances memory userBefore = getBalances(address(user));
        Balances memory wellBefore = getBalances(address(well));
        _;
        Balances memory userAfter = getBalances(address(user));
        Balances memory wellAfter = getBalances(address(well));
        // no change in token balances
        for (uint i = 0; i < tokens.length; ++i) {
            assertEq(userAfter.tokens[i], userBefore.tokens[i], "user token balance mismatch");
            assertEq(wellAfter.tokens[i], wellBefore.tokens[i], "well token balance mismatch");
        }
    }

    //////////// EDGE CASE: SWAP AMOUNT BIGGER THAN BALANCE ////////////
    
    /// @dev 
    function testFuzz_getSwapIn_revertIf_insufficientWellBalance(uint amountOut, uint i) prank(user) public {
        IERC20[] memory _tokens = well.tokens();
        Balances memory wellBalances = getBalances(address(well));
        vm.assume(i < _tokens.length);

        // request more than the Well has. there is no input amount that could do this.
        vm.assume(amountOut > wellBalances.tokens[i]);
        vm.assume(amountOut <= uint128(type(int128).max));

        // swap token `i` -> all other tokens
        for (uint j = 0; j < _tokens.length; ++j) {
            if (j != i) {
                vm.expectRevert("Well: insufficient balances");
                well.getSwapIn(tokens[i], tokens[j], amountOut);
            }
        }
    }

    /// @dev 
    function testFuzz_getSwapOut_revertIf_insufficientWellBalance(uint amountIn, uint i) prank(user) public {
        // Deploy a new Well with a poorly engineered pricing function.
        // Its `getBalance` function can return an amount greater than
        // the Well holds.
        IWellFunction badFunction = new MockFunctionBad();
        Well badWell = new Well(
            "Bad Well",
            "BADWELL",
            tokens,
            Call(address(badFunction), ""),
            pumps
        );
        
        // check assumption that balances are empty
        Balances memory wellBalances = getBalances(address(badWell));
        assertEq(wellBalances.tokens[0], 0, "bad assumption: wellBalances.tokens[0] != 0");
        assertEq(wellBalances.tokens[1], 0, "bad assumption: wellBalances.tokens[1] != 0");

        IERC20[] memory _tokens = badWell.tokens();
        vm.assume(i < _tokens.length); // swap token `i` -> all other tokens

        // find an input amount that produces an output amount higher than what the Well has.
        // When the Well is deployed it has zero balances, so any nonzero value should revert.
        vm.assume(amountIn > 0);
        vm.assume(amountIn <= uint128(type(int128).max));   

        // swap token `i` -> all other tokens
        for(uint j = 0; j < _tokens.length; ++j) {
            if (j != i) {
                vm.expectRevert("Well: insufficient balances");
                badWell.getSwapOut(tokens[i], tokens[j], amountIn);
            }
        }
    }

}
