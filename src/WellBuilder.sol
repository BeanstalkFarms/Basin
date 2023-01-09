// SPDX-License-Identifier: MIT

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
 * Well Builder is an instance of a Well factory.
 * Wells can be permissionlessly built given tokens, a well function and optionally a pump.
 **/

contract WellBuilder is IWellBuilder, ReentrancyGuard {

    using LibContractInfo for address;
    using SafeCast for uint;

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


        emit BuildWell(well, tokens, wellFunction, pump);
    }
}
