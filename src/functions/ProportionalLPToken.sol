// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {Math} from "oz/utils/math/Math.sol";

/**
 * @title ProportionalLPToken
 * @notice Defines a proportional relationship between the supply of LP tokens
 * and the amount of each underlying token for an N-token Well.
 * @dev When removing `s` LP tokens with a Well with `S` LP token supply, the user
 * recieves `s * b_i / S` of each underlying token.
 */
abstract contract ProportionalLPToken is IWellFunction {
    using Math for uint256;

    function calcLPTokenUnderlying(
        uint256 lpTokenAmount,
        uint256[] calldata reserves,
        uint256 lpTokenSupply,
        bytes calldata
    ) external pure returns (uint256[] memory underlyingAmounts) {
        underlyingAmounts = new uint256[](reserves.length);
        for (uint256 i; i < reserves.length; ++i) {
            underlyingAmounts[i] = lpTokenAmount.mulDiv(reserves[i], lpTokenSupply);
        }
    }
}
