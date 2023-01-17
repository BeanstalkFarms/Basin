/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

/**
 * @title Well Function Interface
 * @author Publius
 */
interface IWellFunction {

    /**
     * @notice Gets the jth balance given a list of balances and LP token supply.
     * @param balances A list of token balances. The jth balance will be ignored, but a placeholder must be provided.
     * @param j The index of the balance to solve for
     * @param lpTokenSupply The supply of LP tokens
     * @param data Well function data provided on every call
     * @return balance The resulting balance at the jth index
     */
    function getBalance(
        uint256[] memory balances,
        uint256 j,
        uint256 lpTokenSupply,
        bytes calldata data
    ) external view returns (uint256 balance);

    /**
     * @notice Gets the LP token supply given a list of balances.
     * @param balances A list of token balances
     * @param data Well function data provided on every call
     * @return lpTokenSupply The resulting supply of LP tokens
     */
    function getLpTokenSupply(
        uint256[] memory balances,
        bytes calldata data
    ) external view returns (uint256 lpTokenSupply);

    /**
     * @notice Returns the name of the Well function.
     * @dev Used in Well building.
     */
    function name() external view returns (string memory);

    /**
     * @notice Returns the symbol of the Well function.
     * @dev Used in Well building.
     */
    function symbol() external view returns (string memory);
}