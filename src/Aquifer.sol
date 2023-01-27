/**
 * SPDX-License-Identifier: MIT
 *
 */

pragma solidity ^0.8.17;

import {ReentrancyGuard} from "oz/security/ReentrancyGuard.sol";
import {SafeCast} from "oz/utils/math/SafeCast.sol";

import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {IAquifer} from "src/interfaces/IAquifer.sol";
import {IAuger} from "src/interfaces/IAuger.sol";
import {Well, IWell, Call, IERC20} from "src/Well.sol";
import {LibContractInfo} from "src/libraries/LibContractInfo.sol";

/**
 * @title Aquifer
 * @author Publius
 * @notice Aquifer is a permissionless Well registry.
 */
contract Aquifer is IAquifer, ReentrancyGuard {
    using LibContractInfo for address;
    using SafeCast for uint;

    uint public numberOfWells;

    mapping(uint => address) wellsByIndex;
    mapping(bytes32 => address[]) wellsBy2Tokens;
    mapping(bytes32 => address[]) wellsByNTokens;

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
        IERC20[] calldata tokens,
        Call calldata wellFunction,
        Call[] calldata pumps,
        IAuger auger
    )
        external
        nonReentrant
        returns (address well)
    {
        for (uint i; i < tokens.length - 1; i++) {
            require(tokens[i] < tokens[i + 1], "LibWell: Tokens not alphabetical");
        }

        // Prepare
        IWellFunction wellFunction_ = IWellFunction(wellFunction.target);

        // name is in format `<token0Symbol>:...:<tokenNSymbol> <wellFunctionName> Well`
        // symbol is in format `<token0Symbol>...<tokenNSymbol><wellFunctionSymbol>w`
        string memory name = address(tokens[0]).getSymbol();
        string memory symbol = name;
        for (uint i = 1; i < tokens.length; ++i) {
            name = string.concat(name, ":", address(tokens[i]).getSymbol());
            symbol = string.concat(symbol, address(tokens[i]).getSymbol());
        }
        name = string.concat(name, " ", wellFunction_.name(), " Well");
        symbol = string.concat(symbol, wellFunction_.symbol(), "w");

        // Bore
        well = auger.bore(name, symbol, tokens, wellFunction, pumps);

        // Index
        _indexWell(well, tokens);
        emit BoreWell(well, tokens, wellFunction, pumps, address(auger));
    }

    /// @dev see {IAquifer.getWellByIndex}
    function getWellByIndex(uint index) external view returns (address well) {
        well = wellsByIndex[index];
    }

    /// @dev see {IAquifer.getWellsBy2Tokens}
    function getWellsBy2Tokens(IERC20 token0, IERC20 token1) public view returns (address[] memory wells) {
        wells = wellsBy2Tokens[keccak256(abi.encode(token0, token1))];
    }

    /// @dev see {IAquifer.getWellBy2Tokens}
    function getWellBy2Tokens(IERC20 token0, IERC20 token1, uint i) public view returns (address well) {
        well = getWellsBy2Tokens(token0, token1)[i];
    }

    /// @dev see {IAquifer.getWellsByNTokens}
    function getWellsByNTokens(IERC20[] calldata tokens) public view returns (address[] memory wells) {
        if (tokens.length == 2) wells = getWellsBy2Tokens(tokens[0], tokens[1]);
        else wells = wellsByNTokens[keccak256(abi.encode(tokens))];
    }

    /// @dev see {IAquifer.getWellByNTokens}
    function getWellByNTokens(IERC20[] calldata tokens, uint i) external view returns (address well) {
        if (tokens.length == 2) well = getWellBy2Tokens(tokens[0], tokens[1], i);
        else well = getWellsByNTokens(tokens)[i];
    }

    /**
     * @dev Indexes a Well by its tokens.
     */
    function _indexWell(address well, IERC20[] memory tokens) private {
        wellsByIndex[numberOfWells] = well;
        numberOfWells++;

        for (uint i; i < tokens.length - 1; ++i) {
            for (uint j = i + 1; j < tokens.length; ++j) {
                wellsBy2Tokens[keccak256(abi.encode(tokens[i], tokens[j]))].push(well);
            }
        }

        // For gas efficiency reasons, if the number of tokens is 2, don't need to store it in both mappings.
        if (tokens.length > 2) {
            wellsByNTokens[keccak256(abi.encode(tokens))].push(well);
        }
    }
}
