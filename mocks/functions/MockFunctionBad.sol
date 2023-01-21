/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import {IWellFunction} from "src/interfaces/IWellFunction.sol";

/**
 * @dev Implements a mock broken WellFunction implementation.
 * 
 * Used to verify that {Well.getSwap} throws an error when a Well function
 * returns a balance that is higher than Well balances.
 * 
 * DO NOT COPY IN PRODUCTION.
 */
contract MockFunctionBad is IWellFunction {

    function getLpTokenSupply(
        uint256[] memory balances,
        bytes calldata data
    ) external pure returns (uint lpTokenSupply) {
        return balances[0] + balances[1];
    }

    /// @dev returns non-zero regardless of balances & lp token supply. WRONG!
    function getBalance(
        uint256[] memory balances,
        uint256 j,
        uint256 lpTokenSupply,
        bytes calldata data
    ) external pure returns (uint balance) {
        return 1000;
    }

    function name() external override pure returns (string memory) {
        revert();
    }

    function symbol() external override pure returns (string memory) {
        revert();
    }
}