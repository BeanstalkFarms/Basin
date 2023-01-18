// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "src/interfaces/IWellBuilder.sol";
import "src/Well.sol";

/**
 * @title Well Builder 
 * @author Publius
 */
contract WellBuilder is IWellBuilder {
    constructor() {}

    /// @dev see {IWellBuilder.buildWell}
    function buildWell(
        string calldata name,
        string calldata symbol,
        IERC20[] calldata tokens,
        Call calldata wellFunction,
        Call calldata pump
    ) external payable returns (address well) {
        well = address(new Well(tokens, wellFunction, pump, name, symbol));
    }
}