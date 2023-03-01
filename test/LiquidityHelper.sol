// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, IERC20, Balances, Call, MockToken, Well, console} from "test/TestHelper.sol";
import {MockFunctionBad} from "mocks/functions/MockFunctionBad.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";

/**
 * @dev Stores the expected change in balance for User & Well throughout adding liquidity.
 */
struct AddLiquidityAction {
    uint[] amounts;
    uint lpAmountOut;
    address recipient;
}

/**
 * @dev Stores the expected change in balance for User & Well throughout remove liquidity.
 */
struct RemoveLiquidityAction {
    uint[] amounts;
    uint lpAmountIn;
    address recipient;
}

/**
 * @dev Holds a snapshot of User & Well balances. Used to calculate the change
 * in balanace across some action in the Well.
 */
struct LiquiditySnapshot {
    Balances user;
    Balances well;
    uint[] reserves;
}

/**
 * @dev Provides common assertions when testing adding and removing liquidity.
 *
 * NOTE: Uses globals inherited from TestHelper.
 */
contract LiquidityHeler is TestHelper {
    event AddLiquidity(uint[] amounts, uint lpAmountOut, address recipient);
    event RemoveLiquidity(uint lpAmountIn, uint[] tokenAmountsOut, address recipient);

    function beforeAddLiquidity(
        uint[] memory amounts,
        uint lpAmountOut,
        address recipient
    ) internal returns (LiquiditySnapshot memory, AddLiquidityAction memory) {
        AddLiquidityAction memory action;

        action.amounts = amounts;
        action.lpAmountOut = lpAmountOut;
        action.recipient = recipient;

        return beforeAddLiquidity(action);
    }

    function beforeAddLiquidity(AddLiquidityAction memory action)
        internal
        returns (LiquiditySnapshot memory, AddLiquidityAction memory)
    {
        LiquiditySnapshot memory beforeSnapshot = _newSnapshot();

        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(action.amounts, action.lpAmountOut, action.recipient);

        return (beforeSnapshot, action);
    }

    function afterAddLiquidity(LiquiditySnapshot memory beforeSnapshot, AddLiquidityAction memory action) internal {
        LiquiditySnapshot memory afterSnapshot = _newSnapshot();

        // Check that the LP token balance of the recipient increased by the expected amount
        assertEq(afterSnapshot.user.lp, beforeSnapshot.user.lp + action.lpAmountOut);

        // Check that the user token balances decremented by the correct amount
        for (uint i = 0; i < tokens.length; i++) {
            assertEq(afterSnapshot.user.tokens[i], beforeSnapshot.user.tokens[i] - action.amounts[i]);
        }

        // Check that the well balances incremented by the correct amount
        for (uint i = 0; i < tokens.length; i++) {
            assertEq(afterSnapshot.well.tokens[i], beforeSnapshot.well.tokens[i] + action.amounts[i]);
        }
    }

    function beforeRemoveLiquidity(
        uint lpAmountIn,
        uint[] memory amounts,
        address recipient
    ) internal returns (LiquiditySnapshot memory, RemoveLiquidityAction memory) {
        RemoveLiquidityAction memory action;

        action.lpAmountIn = lpAmountIn;
        action.amounts = amounts;
        action.recipient = recipient;

        return beforeRemoveLiquidity(action);
    }

    function beforeRemoveLiquidity(RemoveLiquidityAction memory action)
        internal
        returns (LiquiditySnapshot memory, RemoveLiquidityAction memory)
    {
        LiquiditySnapshot memory beforeSnapshot = _newSnapshot();

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(action.lpAmountIn, action.amounts, action.recipient);

        return (beforeSnapshot, action);
    }

    function afterRemoveLiquidity(
        LiquiditySnapshot memory beforeSnapshot,
        RemoveLiquidityAction memory action
    ) internal {
        LiquiditySnapshot memory afterSnapshot = _newSnapshot();

        // Check that the LP token balance of the recipient decreased by the expected amount
        assertEq(afterSnapshot.user.lp, beforeSnapshot.user.lp - action.lpAmountIn);

        // Check that the user token balances incremented by the correct amount
        for (uint i = 0; i < tokens.length; i++) {
            assertEq(afterSnapshot.user.tokens[i], beforeSnapshot.user.tokens[i] + action.amounts[i]);
        }

        // Check that the well balances decremented by the correct amount
        for (uint i = 0; i < tokens.length; i++) {
            assertEq(afterSnapshot.well.tokens[i], beforeSnapshot.well.tokens[i] - action.amounts[i]);
        }
    }

    function _newSnapshot() internal view returns (LiquiditySnapshot memory snapshot) {
        snapshot.user = getBalances(user, well);
        snapshot.well = getBalances(address(well), well);
        snapshot.reserves = well.getReserves();
    }
}
