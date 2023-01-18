/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "src/interfaces/IWell.sol";

/**
 * @author Publius
 * @title Well Builder Inferface
 */
interface IWellBuilder {

    /**
     * @notice Emitted when a Well is built.
     * @param well The address of the Well
     * @param tokens The tokens in the Well
     * @param wellFunction The Well function
     * @param pumps The Pumps attached to the Well
     */
    event BuildWell(
        address well,
        IERC20[] tokens,
        Call wellFunction,
        Call[] pumps
    );

    /**
     * @notice Builds a Well with the provided components.
     * @param tokens The tokens in the Well
     * @param wellFunction The Well function
     * @param pumps The Pumps attached to the Well
     * @return wellAddress The address of the Well
     */
    function buildWell(
        IERC20[] calldata tokens,
        Call calldata wellFunction,
        Call[] calldata pumps
    ) external payable returns (address wellAddress);

    /**
     * @notice Returns the Well at a given index.
     */
    function getWellByIndex(uint index) external view returns (address well);

    /**
     * @notice Returns all Wells with a given pair of tokens.
     */
    function getWellsBy2Tokens(IERC20 token0, IERC20 token1) external view returns (address[] memory wells);

    /**
     * @notice Returns the `i`th Well with a given pair of tokens.
     */
    function getWellBy2Tokens(IERC20 token0, IERC20 token1, uint i) external view returns (address well);

    /**
     * @notice Returns all Wells with a given list of tokens.
     */
    function getWellsByNTokens(IERC20[] calldata tokens) external view returns (address[] memory wells);

    /**
     * @notice Returns the `i`th Well with a given list of tokens.
     */
    function getWellByNTokens(IERC20[] calldata tokens, uint i) external view returns (address well);
}
