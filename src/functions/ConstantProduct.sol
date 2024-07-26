// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IBeanstalkWellFunction} from "src/interfaces/IBeanstalkWellFunction.sol";
import {ProportionalLPToken} from "src/functions/ProportionalLPToken.sol";
import {LibMath} from "src/libraries/LibMath.sol";

/**
 * @title ConstantProduct
 * @author Brendan
 * @notice Constant product pricing function for Wells with N tokens.
 * @dev Constant Product Wells use the formula:
 *  `π(b_i) = (s / n)^n`
 *
 * Where:
 *  `s` is the supply of LP tokens
 *  `b_i` is the reserve at index `i`
 *  `n` is the number of tokens in the Well
 *
 * Note: Using too many tokens in a Constant Product Well may result in overflow.
 */
contract ConstantProduct is ProportionalLPToken, IBeanstalkWellFunction {
    using LibMath for uint256;

    uint256 constant CALC_RATE_PRECISION = 1e18;

    /// @dev `s = π(b_i)^(1/n) * n`
    function calcLpTokenSupply(
        uint256[] calldata reserves,
        bytes calldata
    ) external pure override returns (uint256 lpTokenSupply) {
        lpTokenSupply = _prodX(reserves).nthRoot(reserves.length) * reserves.length;
    }

    /// @dev `b_j = (s / n)^n / π_{i!=j}(b_i)`
    function calcReserve(
        uint256[] calldata reserves,
        uint256 j,
        uint256 lpTokenSupply,
        bytes calldata
    ) external pure override returns (uint256 reserve) {
        uint256 n = reserves.length;
        reserve = (lpTokenSupply / n) ** n;
        for (uint256 i; i < n; ++i) {
            if (i != j) reserve = reserve / reserves[i];
        }
    }

    function name() external pure override returns (string memory) {
        return "Constant Product";
    }

    function symbol() external pure override returns (string memory) {
        return "CP";
    }

    /// @dev calculate the mathematical product of an array of uint256[]
    function _prodX(uint256[] memory xs) private pure returns (uint256 pX) {
        pX = xs[0];
        uint256 length = xs.length;
        for (uint256 i = 1; i < length; ++i) {
            pX = pX * xs[i];
        }
    }

    /// @dev `b_j = (π(b_i) * r_j / (Σ_{i != j}(r_i)/(n-1)))^(1/n)`
    function calcReserveAtRatioSwap(
        uint256[] calldata reserves,
        uint256 j,
        uint256[] calldata ratios,
        bytes calldata
    ) external pure override returns (uint256 reserve) {
        uint256 sumRatio = 0;
        for (uint256 i; i < reserves.length; ++i) {
            if (i != j) sumRatio += ratios[i];
        }
        sumRatio /= reserves.length - 1;
        reserve = _prodX(reserves) * ratios[j] / sumRatio;
        reserve = reserve.nthRoot(reserves.length);
    }

    /// @dev `b_j = Σ_{i != j}(b_i * r_j / r_i) / (n-1)`
    function calcReserveAtRatioLiquidity(
        uint256[] calldata reserves,
        uint256 j,
        uint256[] calldata ratios,
        bytes calldata
    ) external pure override returns (uint256 reserve) {
        for (uint256 i; i < reserves.length; ++i) {
            if (i != j) {
                reserve += ratios[j] * reserves[i] / ratios[i];
            }
        }
        reserve /= reserves.length - 1;
    }

    function calcRate(
        uint256[] calldata reserves,
        uint256 i,
        uint256 j,
        bytes calldata
    ) external pure returns (uint256 rate) {
        return reserves[i] * CALC_RATE_PRECISION / reserves[j];
    }
}
