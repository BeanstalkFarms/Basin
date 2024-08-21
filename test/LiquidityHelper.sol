// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TestHelper, IERC20, Balances, Call, MockToken, Well, console, Snapshot} from "test/TestHelper.sol";
import {MockFunctionBad} from "mocks/functions/MockFunctionBad.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";

/**
 * @dev Stores the expected change in balance for User & Well throughout adding liquidity.
 */
struct AddLiquidityAction {
    uint256[] amounts;
    uint256[] fees;
    uint256 lpAmountOut;
    address recipient;
}

/**
 * @dev Stores the expected change in balance for User & Well throughout remove liquidity.
 */
struct RemoveLiquidityAction {
    uint256[] amounts;
    uint256[] fees;
    uint256 lpAmountIn;
    address recipient;
}

/**
 * @dev Provides common assertions when testing adding and removing liquidity.
 *
 * NOTE: Uses globals inherited from TestHelper.
 */
contract LiquidityHelper is TestHelper {
    event AddLiquidity(uint256[] amounts, uint256 lpAmountOut, address recipient);
    event RemoveLiquidity(uint256 lpAmountIn, uint256[] tokenAmountsOut, address recipient);

    function beforeAddLiquidity(
        uint256[] memory amounts,
        uint256 lpAmountOut,
        address recipient
    ) internal returns (Snapshot memory, AddLiquidityAction memory) {
        AddLiquidityAction memory action;

        action.amounts = amounts;
        action.lpAmountOut = lpAmountOut;
        action.recipient = recipient;

        return beforeAddLiquidity(action);
    }

    function beforeAddLiquidity(
        AddLiquidityAction memory action
    ) internal returns (Snapshot memory, AddLiquidityAction memory) {
        Snapshot memory beforeSnapshot = _newSnapshot();

        uint256[] memory amountToTransfer = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            amountToTransfer[i] = action.fees[i] > 0 ? action.fees[i] : action.amounts[i];
        }

        vm.expectEmit(true, true, true, true, address(well));
        emit AddLiquidity(amountToTransfer, action.lpAmountOut, action.recipient);

        return (beforeSnapshot, action);
    }

    function afterAddLiquidity(Snapshot memory beforeSnapshot, AddLiquidityAction memory action) internal {
        Snapshot memory afterSnapshot = _newSnapshot();

        // Check that the LP token balance of the recipient increased by the expected amount
        assertEq(afterSnapshot.user.lp, beforeSnapshot.user.lp + action.lpAmountOut);

        // Check that the user token balances decremented by the correct amount
        for (uint256 i; i < tokens.length; i++) {
            assertEq(afterSnapshot.user.tokens[i], beforeSnapshot.user.tokens[i] - action.amounts[i]);
        }

        // Check that the well balances incremented by the correct amount
        for (uint256 i; i < tokens.length; i++) {
            uint256 valueToAdd = action.fees[i] > 0 ? action.fees[i] : action.amounts[i];
            assertEq(afterSnapshot.well.tokens[i], beforeSnapshot.well.tokens[i] + valueToAdd);
        }
    }

    function beforeRemoveLiquidity(
        uint256 lpAmountIn,
        uint256[] memory amounts,
        address recipient
    ) internal returns (Snapshot memory, RemoveLiquidityAction memory) {
        RemoveLiquidityAction memory action;

        action.lpAmountIn = lpAmountIn;
        action.amounts = amounts;
        action.recipient = recipient;

        return beforeRemoveLiquidity(action);
    }

    function beforeRemoveLiquidity(
        RemoveLiquidityAction memory action
    ) internal returns (Snapshot memory, RemoveLiquidityAction memory) {
        Snapshot memory beforeSnapshot = _newSnapshot();

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(action.lpAmountIn, action.amounts, action.recipient);

        return (beforeSnapshot, action);
    }

    function afterRemoveLiquidity(Snapshot memory beforeSnapshot, RemoveLiquidityAction memory action) internal {
        Snapshot memory afterSnapshot = _newSnapshot();

        // Check that the LP token balance of the recipient decreased by the expected amount
        assertEq(afterSnapshot.user.lp, beforeSnapshot.user.lp - action.lpAmountIn);

        // Check that the user token balances incremented by the correct amount
        for (uint256 i; i < tokens.length; i++) {
            assertEq(afterSnapshot.user.tokens[i], beforeSnapshot.user.tokens[i] + action.amounts[i]);
        }

        // Check that the well balances decremented by the correct amount
        for (uint256 i; i < tokens.length; i++) {
            assertEq(afterSnapshot.well.tokens[i], beforeSnapshot.well.tokens[i] - action.amounts[i]);
        }
    }

    function _amountAferFees(
        uint256[] memory amounts,
        uint256[] memory fees
    ) internal view returns (uint256[] memory) {
        uint256[] memory amountAfterFees = new uint256[](tokens.length);

        for (uint256 i; i < tokens.length; i++) {
            amounts[i] = amounts[i] - fees[i];
        }

        return amountAfterFees;
    }
}
