/**
 * SPDX-License-Identifier: MIT
**/

pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

/**
 * @author Publius
 * @title Well Function Interface
 */
interface IWellFunction {

    /**
     * @notice Gets the jth balance given a list of balances and LP token supply.
     * @param data Well function data provided on every call
     * @param balances A list of token balances. The jth balance will be ignored, but a placeholder must be provided.
     * @param j The index of the balance to solve for
     * @param lpTokenSupply The supply of LP tokens
     * @return balance The balance at the jth index
     */
    function getBalance(
        bytes calldata data,
        uint256[] memory balances,
        uint256 j,
        uint256 lpTokenSupply
    ) external view returns (uint256 balance);

    /**
     * @notice Gets the LP token supply given a list of balances.
     * @param data Well function data provided on every call
     * @param balances A list of token balances
     * @return lpTokenSupply The supply of LP tokens given the list of balances
     */
    function getLpTokenSupply(
        bytes calldata data,
        uint256[] memory balances
    ) external view returns (uint256 lpTokenSupply);

    /**
     * @notice Returns the name of the Well function. Used in Well building.
     */
    function name() external view returns (string memory);

    /**
     * @notice Returns the symbol of the Well function. Used in Well building.
     */
    function symbol() external view returns (string memory);
}