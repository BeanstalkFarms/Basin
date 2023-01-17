/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "src/interfaces/IWellBuilder.sol";
import "src/Well.sol";
import "src/libraries/LibContractInfo.sol";
import "oz/security/ReentrancyGuard.sol";
import "oz/utils/math/SafeCast.sol";

/**
 * @author Publius
 * @title Well Builder 
 * @dev
 * Well Builder is an instance of a Well factory and Well registry.
 * Wells can be permissionlessly built given tokens, a well function and optionally a pump.
 * Wells are index by order of creation, each pair of 2 tokens, and all the tokens in a Well.
 */
contract WellBuilder is IWellBuilder, ReentrancyGuard {

    using LibContractInfo for address;
    using SafeCast for uint;

    uint public numberOfWells;

    mapping(uint => address) wellsByIndex;
    mapping(bytes32 => address[]) wellsBy2Tokens;
    mapping(bytes32 => address[]) wellsByNTokens;

    constructor() ReentrancyGuard() {}

    /// @dev see {IWellBuilder.buildWell}
    /// tokens in Well info struct must be alphabetically sorted
    function buildWell(
        IERC20[] calldata tokens,
        Call calldata wellFunction,
        Call calldata pump
    ) external nonReentrant payable returns (address well) {
        for (uint i; i < tokens.length - 1; i++) {
            require(
                tokens[i] < tokens[i + 1],
                "LibWell: Tokens not alphabetical"
            );
        }

        // name is in format `<token0Symbol>:...:<tokenNSymbol> <wellFunctionName> Well`
        // symbol is in format `<token0Symbol>...<tokenNSymbol><wellFunctionSymbol>w`
        string memory name = address(tokens[0]).getSymbol();
        string memory symbol = name;
        for (uint i = 1; i < tokens.length; ++i) {
            name = string.concat(name, ":", address(tokens[i]).getSymbol());
            symbol = string.concat(symbol, address(tokens[i]).getSymbol());
        }
        name = string.concat(name, " ", wellFunction.target.getName(), " Well");
        symbol = string.concat(symbol, wellFunction.target.getSymbol(), "w");

        well = address(new Well(tokens, wellFunction, pump, name, symbol));

        indexWell(well, tokens);

        emit BuildWell(well, tokens, wellFunction, pump);
    }

    function indexWell(address well, IERC20[] memory tokens) private {
        wellsByIndex[numberOfWells] = well;
        numberOfWells++;

        for (uint i; i < tokens.length-1; ++i) {
            for (uint j = i+1; j < tokens.length; ++j) {
                wellsBy2Tokens[keccak256(abi.encode(tokens[i], tokens[j]))].push(well);
            }
        }

        // For gas efficiency reasons, if the number of tokens is 2, don't need to store it in both mappings.
        if (tokens.length > 2) {
            wellsByNTokens[keccak256(abi.encode(tokens))].push(well);
        }
    }

    /// @dev see {IWellBuilder.getWellByIndex}
    function getWellByIndex(uint index) external view returns (address well) {
        well = wellsByIndex[index];
    }

    /// @dev see {IWellBuilder.getWellsBy2Tokens}
    function getWellsBy2Tokens(IERC20 token0, IERC20 token1) public view returns (address[] memory wells) {
        wells = wellsBy2Tokens[keccak256(abi.encode(token0, token1))];
    }

    /// @dev see {IWellBuilder.getWellBy2Tokens}
    function getWellBy2Tokens(IERC20 token0, IERC20 token1, uint i) public view returns (address well) {
        well = getWellsBy2Tokens(token0, token1)[i];
    }

    /// @dev see {IWellBuilder.getWellsByNTokens}
    function getWellsByNTokens(IERC20[] calldata tokens) public view returns (address[] memory wells) {
        if (tokens.length == 2) wells = getWellsBy2Tokens(tokens[0], tokens[1]);
        else wells = wellsByNTokens[keccak256(abi.encode(tokens))];
    }

    /// @dev see {IWellBuilder.getWellByNTokens}
    function getWellByNTokens(IERC20[] calldata tokens, uint i) external view returns (address well) {
        if (tokens.length == 2) well = getWellBy2Tokens(tokens[0], tokens[1], i);
        else well = getWellsByNTokens(tokens)[i];
    }
}
