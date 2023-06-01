// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IWellFunction} from "src/interfaces/IWellFunction.sol";

/**
 * @title ProportionalLPToken2
 * @notice Defines a proportional relationship between the supply of LP tokens
 * and the amount of each underlying token for a two-token Well.
 * @dev When removing `s` LP tokens with a Well with `S` LP token supply, the user
 * recieves `s * b_i / S` of each underlying token.
 */
abstract contract ProportionalLPToken2 is IWellFunction {
    function calcLPTokenUnderlying(
        uint lpTokenAmount,
        uint[] calldata reserves,
        uint lpTokenSupply,
        bytes calldata
    ) external pure returns (uint[] memory underlyingAmounts) {
        underlyingAmounts = new uint[](2);
        underlyingAmounts[0] = lpTokenAmount * reserves[0] / lpTokenSupply;
        underlyingAmounts[1] = lpTokenAmount * reserves[1] / lpTokenSupply;
    }
}
