// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibContractInfo} from "src/libraries/LibContractInfo.sol";
import {LibWellConstructor} from "src/libraries/LibWellConstructor.sol";
import {Well, Call, IERC20} from "src/Well.sol";
import {Aquifer} from "src/Aquifer.sol";
import {WellUpgradeable} from "src/WellUpgradeable.sol";
import {LibWellUpgradeableConstructor} from "src/libraries/LibWellUpgradeableConstructor.sol";

abstract contract WellDeployer {
    /**
     * @notice Encode the Well's immutable data, and deploys the well.
     * @param _aquifer The address of the Aquifer which will deploy this Well.
     * @param _wellImplementation The address of the Well implementation.
     * @param _tokens A list of ERC20 tokens supported by the Well.
     * @param _wellFunction A single Call struct representing a call to the Well Function.
     * @param _pumps An array of Call structs representings calls to Pumps.
     * @param _salt The salt to deploy the Well with (`bytes32(0)` for none). See {LibClone}.
     */
    function encodeAndBoreWell(
        address _aquifer,
        address _wellImplementation,
        IERC20[] memory _tokens,
        Call memory _wellFunction,
        Call[] memory _pumps,
        bytes32 _salt
    ) internal returns (Well _well) {
        (bytes memory immutableData, bytes memory initData) =
            LibWellConstructor.encodeWellDeploymentData(_aquifer, _tokens, _wellFunction, _pumps);
        _well = Well(Aquifer(_aquifer).boreWell(_wellImplementation, immutableData, initData, _salt));
    }

    /**
     * @notice Encode the Well's immutable data, and deploys the well. Modified for upgradeable wells.
     * @param _aquifer The address of the Aquifer which will deploy this Well.
     * @param _wellImplementation The address of the Well implementation.
     * @param _tokens A list of ERC20 tokens supported by the Well.
     * @param _wellFunction A single Call struct representing a call to the Well Function.
     * @param _pumps An array of Call structs representings calls to Pumps.
     * @param _salt The salt to deploy the Well with (`bytes32(0)` for none). See {LibClone}.
     */
    function encodeAndBoreWellUpgradeable(
        address _aquifer,
        address _wellImplementation,
        IERC20[] memory _tokens,
        Call memory _wellFunction,
        Call[] memory _pumps,
        bytes32 _salt
    ) internal returns (WellUpgradeable _well) {
        (bytes memory immutableData, bytes memory initData) =
            LibWellUpgradeableConstructor.encodeWellDeploymentData(_aquifer, _tokens, _wellFunction, _pumps);
        _well = WellUpgradeable(Aquifer(_aquifer).boreWell(_wellImplementation, immutableData, initData, _salt));
    }
}
