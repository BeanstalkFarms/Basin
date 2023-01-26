/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import {IERC20, SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";
import {IWell, Call} from "src/interfaces/IWell.sol";
import {IAuger} from "src/interfaces/IAuger.sol";

/**
 * @author Publius
 * @title Aquifer Inferface
 */
interface IAquifer {

    /**
     * @notice Emitted when a Well is bored.
     * @param well The address of the new Well
     * @param tokens The tokens in the Well
     * @param wellFunction The Well function
     * @param pumps The pumps to bore in the Well
     * @param auger The auger that bored the Well
     */
    event BoreWell(
        address well,
        IERC20[] tokens,
        Call wellFunction,
        Call[] pumps,
        address auger
    );

    /**
     * @notice bores a Well with given parameters
     * @param tokens The tokens in the Well
     * @param wellFunction The Well function
     * @param pumps The pumps in the Well
     * @param auger The auger to bore the Well with
     * @return wellAddress The address of the Well
     */
    function boreWell(
        IERC20[] calldata tokens,
        Call calldata wellFunction,
        Call[] calldata pumps,
        IAuger auger
    ) external returns (address wellAddress);

    /**
     * @notice returns the Well at a given index.
     */
    function getWellByIndex(uint index) external view returns (address well);

    /**
     * @notice returns all wells with a given pair of tokens.
     */
    function getWellsBy2Tokens(IERC20 token0, IERC20 token1) external view returns (address[] memory wells);

    /**
     * @notice returns the ith well with a given pair of tokens.
     */
    function getWellBy2Tokens(IERC20 token0, IERC20 token1, uint i) external view returns (address well);

    /**
     * @notice returns all wells with a given list of tokens.
     */
    function getWellsByNTokens(IERC20[] calldata tokens) external view returns (address[] memory wells);

    /**
     * @notice returns the ith well with a given list of tokens.
     */
    function getWellByNTokens(IERC20[] calldata tokens, uint i) external view returns (address well);
}