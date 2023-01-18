/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "src/interfaces/IWell.sol";

/**
 * @title Auger Interface
 * @author Publius
 */
interface IAuger {
    
    /**
     * @notice Bores a Well with the provided components.
     * @param name The name of the Well
     * @param symbol The symbol of the Well
     * @param tokens The tokens in the Well
     * @param wellFunction The Well function
     * @param pumps The Pumps to attach to the Well
     * @return well The address of the Well
     */
    function bore(
        string calldata name,
        string calldata symbol,
        IERC20[] calldata tokens,
        Call calldata wellFunction,
        Call[] calldata pumps
    ) external payable returns (address well);
}
