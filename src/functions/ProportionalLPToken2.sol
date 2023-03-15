// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IWellFunction} from "src/interfaces/IWellFunction.sol";

/**
 * @title Proportional LP Token 2 defines the `calcLPTokenUnderlying` function for 
 * Wells with 2 tokens and a proportional relationship between the LP Token and all of the underlying tokens.
 *
 * @dev When removing s LP tokens with a Well with S total LP tokens, they recieve:
 * s * B_i / S of each underlying token.
 */
abstract contract ProportionalLPToken2 is IWellFunction {

    function calcLPTokenUnderlying(
        uint lpTokenAmount,
        uint[] calldata reserves,
        uint lpTokenSupply,
        bytes calldata
    ) external pure override returns (uint[] memory underlyingAmounts) {
        underlyingAmounts = new uint[](2);
        underlyingAmounts[0] = lpTokenAmount * reserves[0] / lpTokenSupply;
        underlyingAmounts[1] = lpTokenAmount * reserves[1] / lpTokenSupply;
    }

}
