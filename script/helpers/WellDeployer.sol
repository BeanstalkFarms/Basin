// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibContractInfo} from "script/helpers/LibContractInfo.sol";
import {Well, Call, IERC20} from "src/Well.sol";
import {Aquifer} from "src/Aquifer.sol";

abstract contract WellDeployer {
    function boreWell(
        address _aquifer,
        address _wellImplementation,
        IERC20[] memory _tokens,
        Call memory _wellFunction,
        Call[] memory _pumps,
        bytes32 _salt
    ) internal returns (Well _well) {
        (bytes memory immutableData, bytes memory initData) = encodeWellDeploymentData(_aquifer, _tokens, _wellFunction, _pumps);
        _well = Well(
            Aquifer(_aquifer).boreWell(
                _wellImplementation,
                immutableData,
                initData,
                _salt
            )
        );
    }

    function encodeWellDeploymentData(
        address _aquifer,
        IERC20[] memory _tokens,
        Call memory _wellFunction,
        Call[] memory _pumps
    ) internal view returns (bytes memory immutableData, bytes memory initData) {
        immutableData = encodeWellImmutableData(_aquifer, _tokens, _wellFunction, _pumps);
        initData = encodeWellInitFunctionCall(_tokens, _wellFunction);
    }

    function encodeWellImmutableData(
        address _aquifer,
        IERC20[] memory _tokens,
        Call memory _wellFunction,
        Call[] memory _pumps
    ) internal pure returns (bytes memory immutableData) {
        bytes memory packedPumps;
        for (uint i; i < _pumps.length; ++i) {
            packedPumps = abi.encodePacked(
                packedPumps,
                _pumps[i].target,
                _pumps[i].data.length,
                _pumps[i].data
            );
        }
        immutableData = abi.encodePacked(
            _aquifer, // aquifer address
            _tokens.length, // number of tokens
            _wellFunction.target, // well function address
            _wellFunction.data.length, // number of well function data
            _pumps.length, // number of pumps
            _tokens,
            _wellFunction.data,
            packedPumps
        );
    }

    function encodeWellInitFunctionCall(
        IERC20[] memory _tokens,
        Call memory _wellFunction
    ) public view returns (bytes memory initFunctionCall) {
        string memory name = LibContractInfo.getSymbol(address(_tokens[0]));
        string memory symbol = name;
        for (uint i = 1; i < _tokens.length; ++i) {
            name = string.concat(name, ":", LibContractInfo.getSymbol(address(_tokens[i])));
            symbol = string.concat(symbol, LibContractInfo.getSymbol(address(_tokens[i])));
        }
        name = string.concat(name, " ", LibContractInfo.getName(_wellFunction.target), " Well");
        symbol = string.concat(symbol, LibContractInfo.getSymbol(_wellFunction.target), "w");
        initFunctionCall = abi.encodeWithSignature(
            "init(string,string)",
            name,
            symbol
        );
    }
}