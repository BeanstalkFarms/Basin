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
     * @param wellAddress The address of the new Well
     * @param wellInfo The Well info struct of the new Well
     * @param wellHash The hash of the Well info of the new Well
     */
    event BuildWell(
        address wellAddress,
        WellInfo wellInfo,
        bytes32 wellHash
    );

    /**
     * Management
    **/

    /**
     * @notice builds a Well with given WellInfo
     * @param wellInfo Well specific data
     * @return wellAddress The address of the Well
     */
    function buildWell(
        WellInfo calldata wellInfo
    ) external payable returns (address wellAddress);

    /**
     * @notice gets the Well address from the Well hash
     * @param wellHash The hash of the Well
     * @return wellAddress The address of the Well
     */
    function getWellAddressFromHash(bytes32 wellHash) external view returns (address wellAddress);

    /**
     * @notice gets the Well address from the Well info
     * @param wellInfo Well specific data
     * @return wellAddress The address of the Well
     */
    function getWellAddress(WellInfo calldata wellInfo) external view returns (address wellAddress);

    /**
     * @notice gets the Well hash from the Well info
     * @param wellInfo Well specific data
     * @return wellHash The hash of the Well
     */
    function getWellHash(WellInfo calldata wellInfo) external pure returns (bytes32 wellHash);
}
