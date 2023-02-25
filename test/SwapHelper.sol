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

    function beforeSwapFrom(
        uint i,
        uint j,
        uint amountIn,
        address user
    ) internal returns (SwapSnapshot memory, SwapAction memory) {
        uint calcAmountOut = uint(well.getSwapOut(tokens[i], tokens[j], amountIn));

        // Setup default values assuming zero fee on transfer
        SwapAction memory act;
        act.userSpends = amountIn;
        act.wellReceives = amountIn;
        act.wellSends = calcAmountOut;
        act.userReceives = calcAmountOut;
    
        return beforeSwapFrom(i, j, user, act);
    }

    function beforeSwapFrom(
        uint i,
        uint j,
        address user,
        SwapAction memory act
    ) internal returns (SwapSnapshot memory, SwapAction memory) {
        SwapSnapshot memory bef = _newSnapshot();

        // This can be emitted any time during top-level test
        vm.expectEmit(true, true, true, true, address(well));
        emit Swap(tokens[i], tokens[j], act.wellReceives, act.wellSends, user);

        return (bef, act);
    }

    function afterSwapFrom(
        uint i,
        uint j,
        SwapSnapshot memory bef,
        SwapAction memory act
    ) public {
        SwapSnapshot memory aft = _newSnapshot();
    
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