// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "src/interfaces/IAuger.sol";
import "src/wells/Well.sol";
/**
 * @title Auger 
 * @author Publius
 */
contract Auger is IAuger {
    constructor() {}

    /// @dev see {IAuger.bore}
    function bore(
        string calldata name,
        string calldata symbol,
        IERC20[] calldata tokens,
        Call calldata wellFunction,
        Call[] calldata pumps
    ) external payable returns (address well) {
        well = address(new Well(name, symbol, tokens, wellFunction, pumps));
    }
}