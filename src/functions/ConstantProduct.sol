// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IBeanstalkWellFunction} from "src/interfaces/IBeanstalkWellFunction.sol";
import {ProportionalLPToken} from "src/functions/ProportionalLPToken.sol";
import {LibMath} from "src/libraries/LibMath.sol";

/**
 * @title ConstantProduct
 * @author Publius
 * @notice Constant product pricing function for Wells with N tokens.
 * @dev Constant Product Wells use the formula:
 *  `π(b_i) = (s / n)^n`
 *
 * Where:
 *  `s` is the supply of LP tokens
 *  `b_i` is the reserve at index `i`
 *  `n` is the number of tokens in the Well
 */
contract ConstantProduct is ProportionalLPToken, IBeanstalkWellFunction {
    using LibMath for uint;

    /// @dev `s = π(b_i)^(1/n) * n`
    function calcLpTokenSupply(
        uint[] calldata reserves,
        bytes calldata
    ) external pure override returns (uint lpTokenSupply) {
        lpTokenSupply = _prodX(reserves).nthRoot(reserves.length) * reserves.length;
    }

    /// @dev `b_j = (s / n)^n / π_{i!=j}(b_i)`
    function calcReserve(
        uint[] calldata reserves,
        uint j,
        uint lpTokenSupply,
        bytes calldata
    ) external pure override returns (uint reserve) {
        uint n = reserves.length;
        reserve = uint((lpTokenSupply / n) ** n);
        for (uint i; i < n; ++i) {
            if (i != j) reserve = reserve / reserves[i];
        }
    }

    function name() external pure override returns (string memory) {
        return "Constant Product";
    }

    function symbol() external pure override returns (string memory) {
        return "CP";
    }

    /// @dev calculate the mathematical product of an array of uint[]
    function _prodX(uint[] memory xs) private pure returns (uint pX) {
        pX = xs[0];
        uint length = xs.length;
        for (uint i = 1; i < length; ++i) {
            pX = pX * xs[i];
        }
    }

    /// @dev `b_j = (π(b_i) * r_j / (Σ_{i != j}(r_i)/(n-1)))^(1/n)`
    function calcReserveAtRatioSwap(
        uint[] calldata reserves,
        uint j,
        uint[] calldata ratios,
        bytes calldata
    ) external pure override returns (uint reserve) {
        uint sumRatio = 0;
        for (uint i = 0; i < reserves.length; ++i) {
            if (i != j) sumRatio += ratios[i];
        }
        sumRatio /= reserves.length-1;
        reserve = _prodX(reserves) * ratios[j] / sumRatio;
        reserve = reserve.nthRoot(reserves.length);
    }

    /// @dev `b_j = Σ_{i != j}(b_i * r_j / r_i) / (n-1)`
    function calcReserveAtRatioLiquidity(
        uint[] calldata reserves,
        uint j,
        uint[] calldata ratios,
        bytes calldata
    ) external pure override returns (uint reserve) {
        for (uint i = 0; i < reserves.length; ++i) {
            if (i != j) {
                reserve += ratios[j] * reserves[i] / ratios[i];
            }
        }
        reserve /= reserves.length-1;
    }
}
