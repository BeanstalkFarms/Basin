/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import {IWell, IERC20, Call} from "src/interfaces/IWell.sol";

/**
 * @title IAuger defines the interface for an Auger.
 * 
 * @dev
 * Augers bore Wells by deploying implementations of the IWell interface.
 * Augers provide an on-chain address reference for Well implementations.
 * A non-malicious Auger should deploy a legitimate Well implementation with the parameters input into bore().
 * When interacing with a Well, always verify the Well was deployed by a valid Auger.
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
