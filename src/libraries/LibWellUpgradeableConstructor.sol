// SPDX-License-Identifier: MIT
// forgefmt: disable-start

pragma solidity ^0.8.20;

import {LibContractInfo} from "src/libraries/LibContractInfo.sol";
import {Call, IERC20} from "src/Well.sol";
import {WellUpgradeable} from "src/WellUpgradeable.sol";

library LibWellUpgradeableConstructor {

    /**
     * @notice Encode the Well's immutable data.
     */
    function encodeWellDeploymentData(
        address _aquifer,
        IERC20[] memory _tokens,
        Call memory _wellFunction,
        Call[] memory _pumps
    ) internal pure returns (bytes memory immutableData, bytes memory initData) {
        immutableData = encodeWellImmutableData(_aquifer, _tokens, _wellFunction, _pumps);
        initData = abi.encodeWithSelector(WellUpgradeable.initNoWellToken.selector);
    }

    /**
     * @notice Encode the Well's immutable data.
     * @param _aquifer The address of the Aquifer which will deploy this Well.
     * @param _tokens A list of ERC20 tokens supported by the Well.
     * @param _wellFunction A single Call struct representing a call to the Well Function.
     * @param _pumps An array of Call structs representings calls to Pumps.
     * @dev `immutableData` is tightly packed, however since `_tokens` itself is
     * an array, each address in the array will be padded up to 32 bytes.
     *
     * Arbitrary-length bytes are applied to the end of the encoded bytes array
     * for easy reading of statically-sized data.
     * 
     */
    function encodeWellImmutableData(
        address _aquifer,
        IERC20[] memory _tokens,
        Call memory _wellFunction,
        Call[] memory _pumps
    ) internal pure returns (bytes memory immutableData) {
        
        immutableData = abi.encodePacked(
            _aquifer,                   // aquifer address
            _tokens.length,             // number of tokens
            _wellFunction.target,       // well function address
            _wellFunction.data.length,  // well function data length
            _pumps.length,              // number of pumps
            _tokens,                    // tokens array
            _wellFunction.data         // well function data (bytes)
        );
        for (uint256 i; i < _pumps.length; ++i) {
            immutableData = abi.encodePacked(
                immutableData,            // previously packed pumps
                _pumps[i].target,       // pump address
                _pumps[i].data.length,  // pump data length
                _pumps[i].data          // pump data (bytes)
            );
        }
    }

    function encodeWellInitFunctionCall(
        IERC20[] memory _tokens,
        Call memory _wellFunction
    ) public view returns (bytes memory initFunctionCall) {
        string memory name = LibContractInfo.getSymbol(address(_tokens[0]));
        string memory symbol = name;
        for (uint256 i = 1; i < _tokens.length; ++i) {
            name = string.concat(name, ":", LibContractInfo.getSymbol(address(_tokens[i])));
            symbol = string.concat(symbol, LibContractInfo.getSymbol(address(_tokens[i])));
        }
        name = string.concat(name, " ", LibContractInfo.getName(_wellFunction.target), " Upgradeable Well");
        symbol = string.concat(symbol, LibContractInfo.getSymbol(_wellFunction.target), "uw");

        // See {Well.init}.
        initFunctionCall = abi.encodeWithSelector(WellUpgradeable.init.selector, name, symbol);
    }

    /**
     * @notice Encode a Call struct representing an arbitrary call to `target` with additional data `data`.
     */
    function encodeCall(address target, bytes memory data) public pure returns (Call memory) {
        return Call(target, data);
    }
}
