// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IWellFunction} from "src/interfaces/IWellFunction.sol";

/**
 * @title ProportionalLPToken
 * @notice Defines a proportional relationship between the supply of LP tokens
 * and the amount of each underlying token for an N-token Well.
 * @dev When removing `s` LP tokens with a Well with `S` LP token supply, the user
 * recieves `s * b_i / S` of each underlying token.
 */
abstract contract ProportionalLPToken is IWellFunction {
    function calcLPTokenUnderlying(
        uint lpTokenAmount,
        uint[] calldata reserves,
        uint lpTokenSupply,
        bytes calldata
    ) external pure returns (uint[] memory underlyingAmounts) {
        underlyingAmounts = new uint[](reserves.length);
        for (uint i; i < reserves.length; ++i) {
            underlyingAmounts[i] = lpTokenAmount * reserves[i] / lpTokenSupply;
        }
    }
}
