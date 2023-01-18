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
     * @notice Builds a Well with the provided components.
     * @param tokens The tokens in the Well
     * @param wellFunction The Well function
     * @param pump The Pump attached to the Well
     * @return well The address of the Well
     */
    function buildWell(
        string calldata name,
        string calldata symbol,
        IERC20[] calldata tokens,
        Call calldata wellFunction,
        Call calldata pump
    ) external payable returns (address well);
}
