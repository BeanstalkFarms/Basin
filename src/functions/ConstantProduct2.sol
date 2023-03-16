// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IBeanstalkWellFunction} from "src/interfaces/IBeanstalkWellFunction.sol";
import {ProportionalLPToken2} from "src/functions/ProportionalLPToken2.sol";
import {LibMath} from "src/libraries/LibMath.sol";

import {console} from "forge-std/console.sol";

/**
 * @author Publius
 * @title Gas efficient Constant Product pricing function for Wells with 2 tokens.
 *
 * Constant Product Wells with 2 tokens use the formula:
 *  `b_0 * b_1 = s^2`
 *
 * Where:
 *  `s` is the supply of LP tokens
 *  `b_i` is the reserve at index `i`
 */
contract ConstantProduct2 is ProportionalLPToken2, IBeanstalkWellFunction {
    using LibMath for uint;

    uint constant EXP_PRECISION = 1e12;

    /// @dev `s = (b_0 * b_1)^(1/2)`
    function calcLpTokenSupply(
        uint[] calldata reserves,
        bytes calldata
    ) external pure override returns (uint lpTokenSupply) {
        lpTokenSupply = (reserves[0] * reserves[1] * EXP_PRECISION).sqrt();
    }

    /// @dev `b_j = s^2 / b_{i | i != j}`
    function calcReserve(
        uint[] calldata reserves,
        uint j,
        uint lpTokenSupply,
        bytes calldata
    ) external view override returns (uint reserve) {
        // Note: potential optimization is to use unchecked math here
        reserve = lpTokenSupply ** 2 / EXP_PRECISION;
        reserve = LibMath.roundedDiv(reserve, reserves[j == 1 ? 0 : 1]);
    }

    function name() external pure override returns (string memory) {
        return "Constant Product";
    }

    function symbol() external pure override returns (string memory) {
        return "CP";
    }

    // TODO: change to pure
    function calcReserveAtRatioSwap(
        uint[] calldata reserves,
        uint j,
        uint[] calldata ratios,
        bytes calldata
    ) external view override returns (uint reserve) {
        uint i = j == 1 ? 0 : 1;
        reserve = ((reserves[i] * reserves[j] * ratios[j]).roundedDiv(ratios[i])).sqrt();
    }

    function calcReserveAtRatioLiquidity(
        uint[] calldata reserves,
        uint j,
        uint[] calldata ratios,
        bytes calldata
    ) external pure override returns (uint reserve) {
        uint i = j == 1 ? 0 : 1;
        reserve = (reserves[i] * ratios[j]).roundedDiv(ratios[i]);
    }
}
