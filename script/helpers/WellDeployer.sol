// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibContractInfo} from "src/libraries/LibContractInfo.sol";
import {LibWellConstructor} from "src/libraries/LibWellConstructor.sol";
import {Well, Call, IERC20} from "src/Well.sol";
import {Aquifer} from "src/Aquifer.sol";

abstract contract WellDeployer {
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
}
