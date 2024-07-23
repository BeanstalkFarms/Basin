// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ReentrancyGuard} from "oz/security/ReentrancyGuard.sol";

import {IAquifer} from "src/interfaces/IAquifer.sol";
import {IWell} from "src/Well.sol";
import {LibClone} from "src/libraries/LibClone.sol";

/**
 * @title Aquifer
 * @author Brendan, Silo Chad, Brean
 * @notice Aquifer is a permissionless Well registry and factory.
 * @dev Aquifer deploys Wells by cloning a pre-deployed Well implementation.
 */
contract Aquifer is IAquifer, ReentrancyGuard {
    using LibClone for address;

    // A mapping of Well address to the Well implementation addresses
    // Mapping gets set on Well deployment
    mapping(address => address) public wellImplementation;

    constructor() ReentrancyGuard() {}

    /**
     * @dev
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
                // Encode the salt with the `msg.sender` address to prevent frontrunning attack
                salt = keccak256(abi.encode(msg.sender, salt));
                well = implementation.cloneDeterministic(immutableData, salt);
            } else {
                well = implementation.clone(immutableData);
            }
        } else {
            if (salt != bytes32(0)) {
                // Encode the salt with the `msg.sender` address to prevent frontrunning attack
                salt = keccak256(abi.encode(msg.sender, salt));
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

        if (!IWell(well).isInitialized()) {
            revert WellNotInitialized();
        }

        // The Aquifer address MUST be set, either (a) via immutable data during cloning,
        // or (b) as a storage variable during an init function call. In either case,
        // the address MUST match the address of the Aquifer that performed deployment.
        if (IWell(well).aquifer() != address(this)) {
            revert InvalidConfig();
        }

        // Save implementation
        wellImplementation[well] = implementation;

        emit BoreWell(
            well,
            implementation,
            IWell(well).tokens(),
            IWell(well).wellFunction(),
            IWell(well).pumps(),
            IWell(well).wellData()
        );
    }

    function predictWellAddress(
        address implementation,
        bytes calldata immutableData,
        bytes32 salt
    ) external view returns (address well) {
        // Aquifer doesn't support using a salt of 0 to deploy a Well at a deterministic address.
        if (salt == bytes32(0)) {
            revert InvalidSalt();
        }
        salt = keccak256(abi.encode(msg.sender, salt));
        if (immutableData.length > 0) {
            well = implementation.predictDeterministicAddress(immutableData, salt, address(this));
        } else {
            well = implementation.predictDeterministicAddress(salt, address(this));
        }
    }
}
