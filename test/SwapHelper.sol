// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TestHelper, IERC20, Balances, Call, MockToken, Well, console, Snapshot} from "test/TestHelper.sol";
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
    uint256 i; // input token index
    uint256 j; // output token index
    uint256 userSpends;
    uint256 wellReceives;
    uint256 wellSends;
    uint256 userReceives;
}

/**
 * @dev Provides common assertions when testing Swaps.
 *
 * NOTE: Uses globals inherited from TestHelper.
 */
contract SwapHelper is TestHelper {
    event AddLiquidity(uint256[] amounts, uint256 lpAmountOut, address recipient);
    event Swap(IERC20 fromToken, IERC20 toToken, uint256 amountIn, uint256 amountOut, address recipient);

    /// @dev Default Swap behavior assuming zero fee on transfer
    function beforeSwapFrom(
        uint256 i,
        uint256 j,
        uint256 amountIn
    ) internal returns (Snapshot memory, SwapAction memory) {
        SwapAction memory act;

        act.i = i;
        act.j = j;
        act.userSpends = amountIn;
        act.wellReceives = amountIn;
        act.wellSends = well.getSwapOut(tokens[i], tokens[j], amountIn);
        act.userReceives = act.wellSends;

        return beforeSwapFrom(act);
    }

    function beforeSwapFrom(SwapAction memory act) internal returns (Snapshot memory, SwapAction memory) {
        Snapshot memory bef = _newSnapshot();

        vm.expectEmit(true, true, true, true, address(well));
        emit Swap(tokens[act.i], tokens[act.j], act.wellReceives, act.wellSends, user);

        return (bef, act);
    }

    function afterSwapFrom(Snapshot memory bef, SwapAction memory act) public {
        Snapshot memory aft = _newSnapshot();
        uint256 i = act.i;
        uint256 j = act.j;

        // Check balances accounting
        assertEq(bef.user.tokens[i] - aft.user.tokens[i], act.userSpends, "Incorrect token[i] User balance");
        assertEq(aft.well.tokens[i], bef.well.tokens[i] + act.wellReceives, "Incorrect token[i] Well balance");
        assertEq(aft.well.tokens[j], bef.well.tokens[j] - act.wellSends, "Incorrect token[j] Well balance");
        assertEq(aft.user.tokens[j] - bef.user.tokens[j], act.userReceives, "Incorrect token[j] User balance");

        // Check that reserves were updated
        uint256[] memory reserves = well.getReserves();
        assertEq(aft.reserves[i], bef.reserves[i] + act.wellReceives, "Incorrect token[i] Well reserve");
        assertEq(aft.reserves[j], bef.reserves[i] - act.wellSends, "Incorrect token[i] Well reserve");

        // Check that no other balances or reserves were changed
        for (uint256 k = 0; k < reserves.length; ++k) {
            if (k == i || k == j) continue;
            assertEq(aft.well.tokens[k], bef.well.tokens[k], "token[k] Well balance changed unexpectedly");
            assertEq(aft.reserves[k], bef.reserves[k], "token[k] Well reserve changed unexpectedly");
        }
    }
}
