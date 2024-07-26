// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {Math} from "oz/utils/math/Math.sol";

/**
 * @title ProportionalLPToken2
 * @notice Defines a proportional relationship between the supply of LP tokens
 * and the amount of each underlying token for a two-token Well.
 * @dev When removing `s` LP tokens with a Well with `S` LP token supply, the user
 * recieves `s * b_i / S` of each underlying token.
 */
abstract contract ProportionalLPToken2 is IWellFunction {
    using Math for uint256;

    function calcLPTokenUnderlying(
        uint256 lpTokenAmount,
        uint256[] calldata reserves,
        uint256 lpTokenSupply,
        bytes calldata
    ) external pure returns (uint256[] memory underlyingAmounts) {
        underlyingAmounts = new uint256[](2);
        underlyingAmounts[0] = lpTokenAmount.mulDiv(reserves[0], lpTokenSupply);
        underlyingAmounts[1] = lpTokenAmount.mulDiv(reserves[1], lpTokenSupply);
    }
}
