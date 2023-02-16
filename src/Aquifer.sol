// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ReentrancyGuard} from "oz/security/ReentrancyGuard.sol";
import {SafeCast} from "oz/utils/math/SafeCast.sol";

import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {IAquifer} from "src/interfaces/IAquifer.sol";
import {Well, IWell, Call, IERC20} from "src/Well.sol";
import {LibClone} from "src/libraries/LibClone.sol";

import {console} from "forge-std/Test.sol";

/**
 * @title Aquifer
 * @author Publius
 * @notice Aquifer is a permissionless Well registry.
 */
contract Aquifer is IAquifer, ReentrancyGuard {
    using SafeCast for uint;
    using LibClone for address;

    mapping(address => address) wellImplementations;

    constructor() ReentrancyGuard() {}

    /**
     * @dev see {IAquifer.boreWell}
     *
     * Tokens in Well info struct must be alphabetically sorted.
     *
     * The Aquifer takes an opinionated stance on the `name` and `symbol` of
     * the deployed Well.
     */
    function boreWell(
        address implementation,
        bytes calldata immutableData,
        bytes calldata initFunctionCall,
        bytes32 salt
    ) external nonReentrant returns (address well) {
        if (immutableData.length > 0) {
            if (salt.length > 0) {
                well = implementation.cloneDeterministic(immutableData, salt);
            } else {
                well = implementation.clone(immutableData);
            }
        } else {
            if (salt.length > 0) {
                well = implementation.cloneDeterministic(salt);
            } else {
                well = implementation.clone();
            }
        }

        if (initFunctionCall.length > 0) {
            (bool success, bytes memory returnData) = well.call(initFunctionCall);
            require(success, string(returnData));
        }

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

    function wellImplementation(address well) external view returns (address implementation) {
        return wellImplementations[well];
    }
}
