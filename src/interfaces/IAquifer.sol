// SPDX-License-Identifier: MIT

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
     * @param implementation The Well implementation
     * @param tokens The tokens in the Well
     * @param wellFunction The Well function
     * @param pumps The pumps to bore in the Well
     * @param wellData The Well data to implement into the Well
     */
    event BoreWell(
        address well, 
        address implementation, 
        IERC20[] tokens, 
        Call wellFunction, 
        Call[] pumps, 
        bytes wellData
    );

    /**
     * @notice bores a Well with given parameters
     * @param implementation The Well implementation to clone
     * @param constructorArgs The arguments to pass to the Well constructor (0x for none)
     * @param initFunctionCall The function call to initialize the Well (0x for none)
     * @param salt The salt to deploy the Well with (0x for none). See {LibClone}.
     * @return wellAddress The address of the Well
     */
    function boreWell(
        address implementation,
        bytes calldata constructorArgs,
        bytes calldata initFunctionCall,
        bytes32 salt
    ) external returns (address wellAddress);

    /**
    * @notice returns the implementation that a given Well was deployed with.
    * @param well The Well to get the implementation of
    * @return implementation The address of the implementation of a Well.
    */
    function wellImplementation(address well) external view returns (address implementation);
}
