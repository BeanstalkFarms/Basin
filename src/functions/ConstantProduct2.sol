/**
 * SPDX-License-Identifier: MIT
 *
 */

pragma solidity ^0.8.17;

import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {LibMath} from "src/libraries/LibMath.sol";

/**
 * @author Publius
 * @title Gas efficient Constant Product pricing function for Wells with 2 tokens.
 *
 * Constant Product Wells with 2 tokens use the formula:
 *  `b_0 * b_1 = (s / 2)^2`
 *
 * Where:
 *  `s` is the supply of LP tokens
 *  `b_i` is the reserve at index `i`
 *  The 2 in `s / 2` follows from the fact that there are 2 tokens in the Well
 */
contract ConstantProduct2 is IWellFunction {
    using LibMath for uint;

    uint constant EXP_PRECISION = 1e18;

    /// @dev `s = (b_0 * b_1)^(1/2) * 2`
    function calcLpTokenSupply(
        uint[] calldata reserves,
        bytes calldata
    ) external pure override returns (uint lpTokenSupply) {
        lpTokenSupply = (reserves[0] * reserves[1] * EXP_PRECISION).sqrt() * 2;
    }

    /// @dev `b_j = (s / 2)^2 / b_{i | i != j}`
    function calcReserve(
        uint[] calldata reserves,
        uint j,
        uint lpTokenSupply,
        bytes calldata
    ) external pure override returns (uint reserve) {
        reserve = uint((lpTokenSupply / 2) ** 2) / EXP_PRECISION;
        reserve = LibMath.roundedDiv(reserve, reserves[j == 1 ? 0 : 1]);
    }

    function name() external pure override returns (string memory) {
        return "Constant Product";
    }

    function symbol() external pure override returns (string memory) {
        return "CP";
    }
}
