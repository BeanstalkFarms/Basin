// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "src/interfaces/IWell.sol";

/**
 * @author Publius
 * @title Well Builder Inferface
 **/

interface IWellBuilder {

    /**
     * @notice Emitted when a Well is built.
     * @param well The address of the new Well
     * @param tokens The tokens in the Well
     * @param wellFunction The Well function
     * @param pump The pump in the Well
     */
    event BuildWell(
        address well,
        IERC20[] tokens,
        Call wellFunction,
        Call pump
    );

    /**
     * Management
    **/

    /**
     * @notice builds a Well with given parameters
     * @param tokens The tokens in the Well
     * @param wellFunction The Well function
     * @param pump The pump in the Well
     * @return wellAddress The address of the Well
     */
    function buildWell(
        IERC20[] calldata tokens,
        Call calldata wellFunction,
        Call calldata pump
    ) external payable returns (address wellAddress);
}
