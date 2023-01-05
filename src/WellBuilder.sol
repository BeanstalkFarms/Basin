// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "src/libraries/LibWellUtilities.sol";
import "src/interfaces/IWellBuilder.sol";
import "src/Well.sol";

/**
 * @author Publius
 * @title Well Builder 
 * @dev
 * Well Builder is both a Well factory and a Well registry for all Wells deployed through the Builder
 * Wells can be permissionlessly built given Well info.
 * Only 1 Well can be deployed for each unique Well info struct.
 * Well addresses are indexed by Well hash for future lookup.
 **/

contract WellBuilder is IWellBuilder {

    mapping(bytes32 => address) wellAddresses;

    /**
     * Management
    **/

    /// @dev see {IWellBuilder.buildWell}
    /// tokens in Well info struct must be alphabetically sorted
    function buildWell(
        WellInfo calldata wellInfo
    ) external payable returns (address wellAddress) {
        for (uint256 i; i < wellInfo.tokens.length - 1; i++) {
            require(
                wellInfo.tokens[i] < wellInfo.tokens[i + 1],
                "LibWell: Tokens not alphabetical"
            );
        }

        bytes32 wellHash = LibWellUtilities.computeWellHash(wellInfo);

        // deploy using create2 to deploy to a deterministic address.
        // create2 call will fail if a Well is already deployed with the Well info argument.
        bytes memory bytecode = type(Well).creationCode;
        assembly { wellAddress := create2(0, add(bytecode, 32), mload(bytecode), wellHash) }
        Well(wellAddress).initialize(wellInfo);

        wellAddresses[wellHash] = wellAddress;
        emit BuildWell(wellAddress, wellInfo, wellHash);
    }

    /// @dev see {IWellBuilder.getWellAddressFromHash}
    function getWellAddressFromHash(bytes32 wellHash) external view returns (address wellAddress) {
        return wellAddresses[wellHash];
    }

    /// @dev see {IWellBuilder.getWellAddress}
    function getWellAddress(WellInfo calldata wellInfo) external view returns (address wellAddress) {
        bytes32 wh = LibWellUtilities.computeWellHash(wellInfo);
        wellAddress = wellAddresses[wh];
    }

    /// @dev see {IWellBuilder.getWellHash}
    function getWellHash(WellInfo calldata wellInfo) external pure returns (bytes32 wellHash) {
        wellHash = LibWellUtilities.computeWellHash(wellInfo);
    }
}
