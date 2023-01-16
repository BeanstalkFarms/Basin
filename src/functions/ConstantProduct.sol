/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "src/interfaces/IWellFunction.sol";
import "src/libraries/LibMath.sol";

/**
 * @author Publius
 * @title Constant Product pricing function for Wells with 2 tokens
 * 
 * Constant Product Wells use the formula:
 *  `π(b_i) = (s / n)^n`
 * 
 * Where:
 *  `s` is the supply of LP tokens
 *  `b_i` is the balance at index `i`
 *  `n` is the number of tokens in the Well
 */
contract ConstantProduct is IWellFunction {
    using LibMath for uint;

    /// @dev `s = π(b_i)^(1/n) * n`
    function getLpTokenSupply(
        bytes calldata,
        uint[] calldata balances
    ) external override pure returns (uint lpTokenSupply) {
        lpTokenSupply = prodX(balances).nthRoot(balances.length) * balances.length;
    }

    /// @dev `b_j = (s / n)^n / π_{i!=j}(b_i)`
    function getBalance(
        bytes calldata,
        uint[] calldata balances,
        uint j,
        uint lpTokenSupply
    ) external override pure returns (uint balance) {
        uint n = balances.length;
        balance = uint((lpTokenSupply / n) ** n);
        for (uint i; i < n; ++i)
            if (i != j) balance = balance / balances[i];
    }

    /// @dev calculate the mathematical product of an array of uint[]
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
}