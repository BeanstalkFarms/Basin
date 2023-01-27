/**
 * SPDX-License-Identifier: MIT
 *
 */

pragma solidity ^0.8.17;

import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {LibMath} from "src/libraries/LibMath.sol";

/**
 * @author Publius
 * @title Constant Product pricing function for Wells with 2 tokens
 *
 * Constant Product Wells use the formula:
 *  `π(b_i) = (s / n)^n`
 *
 * Where:
 *  `s` is the supply of LP tokens
 *  `b_i` is the reserve at index `i`
 *  `n` is the number of tokens in the Well
 */
contract ConstantProduct is IWellFunction {
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
        for (uint i = 1; i < xs.length; ++i) {
            pX = pX * xs[i];
        }
    }
}
