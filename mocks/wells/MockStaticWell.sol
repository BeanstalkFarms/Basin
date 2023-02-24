// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {console} from "test/TestHelper.sol";
import {ReentrancyGuardUpgradeable} from "ozu/security/ReentrancyGuardUpgradeable.sol";
import {IPump} from "src/interfaces/PUMPS/IPump.sol";
import {MockReserveWell} from "mocks/wells/MockReserveWell.sol";
import {ClonePlus} from "src/utils/ClonePlus.sol";
import {Call, IERC20} from "src/Well.sol";

/**
 * @title MockStaticWell 
 * @author Silo Chad
 * @notice Simplified Well implementation which stores configuration in immutable
 * storage during construction.
 */
contract MockStaticWell is ReentrancyGuardUpgradeable, ClonePlus {
    address immutable token0;
    address immutable token1;
    address immutable wellFunctionTarget;
    bytes32 immutable wellFunctionData;
    address immutable pump0Target;
    bytes32 immutable pump0Data;
    address immutable AQUIFER;
    bytes32 immutable WELL_DATA;

    string public name;
    string public symbol;

    constructor(
        IERC20[] memory _tokens,
        Call memory _wellFunction,
        Call[] memory _pumps,
        address _aquifer,
        bytes memory _wellData
    ) {
        require(_tokens.length == 2, "MockStaticWell: invalid tokens");
        require(_pumps.length == 1, "MockStaticWell: invalid pumps");

        token0 = address(_tokens[0]);
        token1 = address(_tokens[1]);
        wellFunctionTarget = _wellFunction.target;
        wellFunctionData = bytes32(_wellFunction.data);
        pump0Target = _pumps[0].target;
        pump0Data = bytes32(_pumps[0].data);
        AQUIFER = _aquifer;
        WELL_DATA = bytes32(_wellData);
    }

    function init(string memory _name, string memory _symbol) public initializer {
        name = _name;
        symbol = _symbol;
    }

    function tokens() public view returns (IERC20[] memory _tokens) {
        _tokens = new IERC20[](2);
        _tokens[0] = IERC20(token0);
        _tokens[1] = IERC20(token1);
    }

    function wellFunction() public view returns (Call memory _wellFunction) {
        _wellFunction = Call(wellFunctionTarget, bytes32ToBytes(wellFunctionData));
    }

    function pumps() public view returns (Call[] memory _pumps) {
        _pumps = new Call[](1);
        _pumps[0] = Call(pump0Target, bytes32ToBytes(pump0Data));
    }

    function aquifer() public view returns (address) {
        return AQUIFER;
    }

    function wellData() public view returns (bytes memory) {
        return bytes32ToBytes(WELL_DATA);
    }
    
    /// @dev Read a uint off the front of immutable storage applied during Clone.
    /// Since the immutable variables defined above are instantiated during
    /// construction, their length is included in the offset; i.e., immutable
    /// vars added using Clone begin at index 0. See {Clone._getImmutableArgsOffset}.
    function immutableDataFromClone() public pure returns (uint) {
        return _getArgUint256(0);
    }

    /// @dev Inefficient way to convert bytes32 back to bytes without padding
    function bytes32ToBytes(bytes32 data) internal pure returns (bytes memory) {
        uint i = 0;
        while (i < 32 && uint8(data[i]) != 0) {
            ++i;
        }
        bytes memory result = new bytes(i);
        i = 0;
        while (i < 32 && data[i] != 0) {
            result[i] = data[i];
            ++i;
        }
        return result;
    }
}
