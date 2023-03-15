// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IWellFunction} from "src/interfaces/IWellFunction.sol";

/**
 * @title Proportional LP Token defines the `calcLPTokenUnderlying` function for 
 * Wells with a proportional relationship between the LP Token and all of the underlying tokens.
 *
 * @dev When removing s LP tokens with a Well with S total LP tokens, they recieve:
 * s * B_i / S of each underlying token.
 */
abstract contract ProportionalLPToken is IWellFunction {

    function calcLPTokenUnderlying(
        uint lpTokenAmount,
        uint[] calldata reserves,
        uint lpTokenSupply,
        bytes calldata
    ) external pure override returns (uint[] memory underlyingAmounts) {
        underlyingAmounts = new uint[](reserves.length);
        for (uint i; i < reserves.length; ++i) {
            underlyingAmounts[i] = lpTokenAmount * reserves[i] / lpTokenSupply;
        }
    }

}
