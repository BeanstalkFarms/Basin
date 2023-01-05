/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "src/interfaces/IWellFunction.sol";
import "src/libraries/LibMath.sol";

/**
 * @author Publius
 * @title Constant Product pricing function for wells with 2 tokens
 * Constant Product Wells use the formula:
 * π(x_i) = (D / n)^n
 * Where
 * x_i are the balances in the pool
 * n is the number of tokens in the pool
 * D is the value weighted number of tokens in the pool
 **/
contract ConstantProduct is IWellFunction {

    using LibMath for uint;

    // D = π(x_i)^(1/n) * n
    function getD(
        bytes calldata,
        uint[] calldata xs
    ) external override pure returns (uint d) {
        d = prodX(xs).nthRoot(xs.length) * xs.length;
    }

    // x_j = (D / n)^n / π_{i!=j}(x_i) 
    function getXj(
        bytes calldata,
        uint[] calldata xs,
        uint j,
        uint d
    ) external override pure returns (uint xj) {
        uint n = xs.length;
        xj = uint((d / n) ** n); // unchecked math is safe here.
        for (uint i; i < xs.length; ++i)
            if (i != j) xj = xj / xs[i];
    }

    function prodX(uint[] memory xs) private pure returns (uint pX) {
        pX = xs[0];
        for (uint i = 1; i < xs.length; ++i)
            pX = pX * xs[i];
    }

    function name() external override pure returns (string memory) {
        return "Constant Product";
    }

    function symbol() external override pure returns (string memory) {
        return "CP";
    }

    // dy = x_i/x_j
    // uses 18 decimal precision
    
    // function getdXidXj(
    //     uint precision,
    //     uint i,
    //     uint j,
    //     uint[] memory xs
    // ) internal pure returns (uint dXi) {
    //     dXi = uint(xs[i]).mul(precision).div(xs[j]);
    // }

    // function getdXdD(
    //     uint precision,
    //     uint i,
    //     uint[] memory xs
    // ) internal pure returns (uint dX) {
    //     uint d = getD(xs);
    //     dX = precision.mul(xs[i]).div(d).mul(xs.length);
    // }

    // function getXAtRatio(
    //     uint[] memory xs,
    //     uint i,
    //     uint[] memory ratios
    // ) internal pure returns (uint x) {
    //     uint xTemp = prodX(xs);
    //     uint sumRatio = 0;
    //     for (uint _i = 0; _i < xs.length; ++_i) {
    //         if (_i != i) sumRatio = sumRatio.add(ratios[_i]);
    //     }
    //     xTemp = xTemp.mul(ratios[i]).div(sumRatio.div(xs.length-1));
    //     x = xTemp.nthRoot(xs.length).touint();
    // }

    // function getXDAtRatio(
    //     uint[] memory xs,
    //     uint i,
    //     uint[] memory ratios
    // ) internal pure returns (uint x) {
    //     uint xSum;
    //     for (uint j = 0; j < xs.length; ++j) {
    //         if (i != j) {
    //             xSum = xSum.add(ratios[i].mul(xs[j]).div(ratios[j]));
    //         }
    //     }
    //     x = xSum.div(xs.length-1).touint();
    // }
}