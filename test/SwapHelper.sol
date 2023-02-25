// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, IERC20, Balances, Call, MockToken, Well, console} from "test/TestHelper.sol";
import {MockFunctionBad} from "mocks/functions/MockFunctionBad.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";

/**
 * @dev Stores the expected change in balance for User & Well throughout a Swap.
 *
 * Gives upstream tests a way to specify expected changes based on the presence
 * of transfer fees. When a token involved in a swap incurs a fee on transfer,
 * one or both of the following is true:
 *
 *  `wellReceives` < `userSpends`
 *  `userReceives` < `wellSends`
 */
struct SwapAction {
    uint i; // input token index
    uint j; // output token index
    uint userSpends;
    uint wellReceives;
    uint wellSends;
    uint userReceives;
}

/**
 * @dev Holds a snapshot of User & Well balances. Used to calculate the change
 * in balanace across some action in the Well.
 */
struct SwapSnapshot {
    Balances user;
    Balances well;
}

contract SwapHelper is TestHelper {
    event AddLiquidity(uint[] amounts, uint lpAmountOut, address recipient);
    event Swap(IERC20 fromToken, IERC20 toToken, uint amountIn, uint amountOut, address recipient);

    /// @dev Default Swap behavior assuming zero fee on transfer
    function beforeSwapFrom(uint i, uint j, uint amountIn) internal returns (SwapSnapshot memory, SwapAction memory) {
        SwapAction memory act;
        act.i = i;
        act.j = j;
        act.userSpends = amountIn;
        act.wellReceives = amountIn;
        act.wellSends = well.getSwapOut(tokens[i], tokens[j], amountIn);
        act.userReceives = act.wellSends;

        return beforeSwapFrom(act);
    }

    function beforeSwapFrom(SwapAction memory act) internal returns (SwapSnapshot memory, SwapAction memory) {
        SwapSnapshot memory bef = _newSnapshot();

        vm.expectEmit(true, true, true, true, address(well));
        emit Swap(tokens[act.i], tokens[act.j], act.wellReceives, act.wellSends, user);

        return (bef, act);
    }

    function afterSwapFrom(SwapSnapshot memory bef, SwapAction memory act) public {
        SwapSnapshot memory aft = _newSnapshot();
        uint i = act.i;
        uint j = act.j;

        assertEq(bef.user.tokens[i] - aft.user.tokens[i], act.userSpends, "Incorrect token[i] user balance");
        assertEq(aft.well.tokens[i], bef.well.tokens[i] + act.wellReceives, "Incorrect token[i] well reserve");
        assertEq(aft.well.tokens[j], bef.well.tokens[j] - act.wellSends, "Incorrect token[j] well reserve");
        assertEq(aft.user.tokens[j] - bef.user.tokens[j], act.userReceives, "Incorrect token[j] user balance");
    }

    function _newSnapshot() internal view returns (SwapSnapshot memory ss) {
        ss.user = getBalances(user, well);
        ss.well = getBalances(address(well), well);
    }
}
