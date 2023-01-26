// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IAuger} from "src/interfaces/IAuger.sol";
import {Well, IERC20, Call} from "src/Well.sol";

/**
 * @title An implementation of an Auger. See {IAuger}. Deploys {Well}.
 * @author Publius, Silo Chad, Brean
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
    )
        external
        payable
        returns (address well)
    {
        well = address(new Well(name, symbol, tokens, wellFunction, pumps));
    }
}
