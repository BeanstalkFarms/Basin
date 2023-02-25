// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, IERC20, Balances, Call, MockToken, Well, console} from "test/TestHelper.sol";
import {MockFunctionBad} from "mocks/functions/MockFunctionBad.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";

struct BeforeSwap {
    Balances user;
    Balances well;
    uint amountIn;
    uint calcAmountOut;
}

contract SwapHelper is TestHelper {

    event AddLiquidity(uint[] amounts, uint lpAmountOut, address recipient);
    event Swap(IERC20 fromToken, IERC20 toToken, uint amountIn, uint amountOut, address recipient);

    function _before_swapFrom(
        uint i,
        uint j,
        uint amountIn,
        address user
    ) internal returns (BeforeSwap memory) {
        Balances memory userBalanceBefore = getBalances(user, well);
        Balances memory wellBalanceBefore = getBalances(address(well), well);

        uint calcAmountOut = uint(well.getSwapOut(tokens[i], tokens[j], amountIn));
        
        vm.expectEmit(true, true, true, true);
        emit Swap(tokens[i], tokens[j], amountIn, calcAmountOut, user);

        return BeforeSwap(
            userBalanceBefore,
            wellBalanceBefore,
            amountIn,
            calcAmountOut
        );
    }

    function _after_swapFrom(
        uint i,
        uint j,
        uint amountOut,
        BeforeSwap memory b
    ) public {
        Balances memory userBalanceBefore = b.user;
        Balances memory wellBalanceBefore = b.well;
        Balances memory userBalanceAfter = getBalances(user, well);
        Balances memory wellBalanceAfter = getBalances(address(well), well);

        assertEq(b.user.tokens[i] - userBalanceAfter.tokens[i], b.amountIn, "Incorrect token[i] user balance");
        assertEq(wellBalanceAfter.tokens[i], b.well.tokens[i] + b.amountIn, "Incorrect token[i] well reserve");

        assertEq(
            userBalanceAfter.tokens[j] - b.user.tokens[j], amountOut, "Incorrect token[j] user balance"
        );
        assertEq(
            wellBalanceAfter.tokens[j], b.well.tokens[j] - amountOut, "Incorrect token[j] well reserve"
        );
    }
}