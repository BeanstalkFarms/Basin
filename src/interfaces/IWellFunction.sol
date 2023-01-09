/**
 * SPDX-License-Identifier: MIT
**/

pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

/**
 * @author Publius
 * @title Well Function Interface
**/
interface IWellFunction {

    /**
     * @notice gets the jth balance given a list of balances and LP token supply
     * @param data well function specific data
     * @param balances A list of balances. Note: the jth balance will be ignored, but a placeholder must be provided.
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
     * @notice gets the LP token supply given a list of balances
     * @param data well function specific data
     * @param balances The x values of the tokens in the well
     * @return lpTokenSupply The d value given the x values
     */
    function getLpTokenSupply(
        bytes calldata data,
        uint256[] memory balances
    ) external view returns (uint256 lpTokenSupply);

    /**
     @notice returns the name of the well function. Used in Well builing.
     */
    function name() external view returns (string memory);

    /**
     @notice returns the symbol of the well function. Used in Well builing.
     */
    function symbol() external view returns (string memory);
}