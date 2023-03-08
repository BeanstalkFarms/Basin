// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ReentrancyGuard} from "oz/security/ReentrancyGuard.sol";
import {SafeCast} from "oz/utils/math/SafeCast.sol";

import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {IAquifer} from "src/interfaces/IAquifer.sol";
import {Well, IWell, Call, IERC20} from "src/Well.sol";
import {LibClone} from "src/libraries/LibClone.sol";

/**
 * @title Aquifer
 * @author Publius, Silo Chad, Brean
 * @notice Aquifer is a permissionless Well registry and factory.
 * @dev Aquifer deploys Wells by cloning a pre-deployed Well implementation.
 */
contract Aquifer is IAquifer, ReentrancyGuard {
    using SafeCast for uint;
    using LibClone for address;

    // A mapping of Well address to the Well implementation addresses
    // Mapping gets set on Well deployment
    mapping(address => address) wellImplementations;

    constructor() ReentrancyGuard() {}

    /**
     * @dev see {IAquifer.boreWell}
     * Use `salt == 0` to deploy a new Well with `create`
     * Use `salt > 0` to deploy a new Well with `create2`
     */
    function boreWell(
        address implementation,
        bytes calldata immutableData,
        bytes calldata initFunctionCall,
        bytes32 salt
    ) external nonReentrant returns (address well) {
        if (immutableData.length > 0) {
            if (salt != bytes32(0)) {
                well = implementation.cloneDeterministic(immutableData, salt);
            } else {
                well = implementation.clone(immutableData);
            }
        } else {
            if (salt != bytes32(0)) {
                well = implementation.cloneDeterministic(salt);
            } else {
                well = implementation.clone();
            }
        }

        if (initFunctionCall.length > 0) {
            (bool success, bytes memory returnData) = well.call(initFunctionCall);
            if (!success) {
                // Next 5 lines are based on https://ethereum.stackexchange.com/a/83577
                if (returnData.length < 68) revert InitFailed("");
                assembly {
                    returnData := add(returnData, 0x04)
                }
                revert InitFailed(abi.decode(returnData, (string)));
            }
        }
        
        // The Aquifer address MUST be set, either (a) via immutable data during cloning,
        // or (b) as a storage variable during an init function call. In either case, 
        // the address MUST match the address of the Aquifer that performed deployment.    
        if(IWell(well).aquifer() != address(this)) {
            revert InvalidConfig();
        }

        // Save implementation
        wellImplementations[well] = implementation;

        emit BoreWell(
            well,
            implementation,
            IWell(well).tokens(),
            IWell(well).wellFunction(),
            IWell(well).pumps(),
            IWell(well).wellData()
        );
    }

    /**
     * @dev see {IAquifer.wellImplementation}
     */
    function wellImplementation(address well) external view returns (address implementation) {
        return wellImplementations[well];
    }
}
