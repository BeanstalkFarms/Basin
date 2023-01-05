/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "src/interfaces/IWellFunction.sol";
import "src/libraries/LibMath.sol";

/**
 * @author Publius
 * @title Gas efficient Constant Product pricing function for wells with 2 tokens
 * Constant Product Wells use the formula:
 * x_0*x_1 = (D / 2)^2
 * Where
 * x_i are the balances in the pool
 * n is the number of tokens in the pool
 * D is the value weighted number of tokens in the pool
 **/
contract ConstantProduct2 is IWellFunction {

    using LibMath for uint;

    // D = n (x_0*x_1)^(1/2) * 2
    function getD(
        bytes calldata,
        uint[] calldata xs
    ) external override pure returns (uint d) {
        d = (xs[0]*xs[1]).sqrt() * 2;
    }

    // x_j = (D / 2)^2 /x_{i | i != j} 
    function getXj(
        bytes calldata,
        uint[] calldata xs,
        uint j,
        uint d
    ) external override pure returns (uint xj) {
        xj = uint((d / 2) ** 2); // unchecked math is safe here.
        xj = xj / xs[j == 1 ? 0 : 1];
    }

    function name() external override pure returns (string memory) {
        return "Constant Product";
    }

    function symbol() external override pure returns (string memory) {
        return "CP";
    }
}