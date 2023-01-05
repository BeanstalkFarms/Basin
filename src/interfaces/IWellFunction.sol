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
     * @notice gets the x value for a given d
     * @param data well function specific data
     * @param xs The x values of the tokens in the well
     * @param j The index of x to solve for
     * @param d The d value
     * @return xj The x value at index j
     */
    function getXj(
        bytes calldata data,
        uint256[] memory xs,
        uint256 j,
        uint256 d
    ) external view returns (uint256 xj);

    /**
     * @notice gets the d value for a given list of x values
     * @param data well function specific data
     * @param xs The x values of the tokens in the well
     * @return d The d value given the x values
     */
    function getD(
        bytes calldata data,
        uint256[] memory xs
    ) external view returns (uint256 d);

    /**
     @notice returns the name of the well function. Used in Well builing.
     */
    function name() external view returns (string memory);

    /**
     @notice returns the symbol of the well function. Used in Well builing.
     */
    function symbol() external view returns (string memory);
}