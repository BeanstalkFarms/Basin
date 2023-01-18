/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "src/interfaces/IWellFunction.sol";
import "src/libraries/LibMath.sol";
import "forge-std/console.sol";

/**
 * @author Publius
 * @title Gas efficient Constant Product pricing function for Wells with 2 tokens.
 * 
 * Constant Product Wells with 2 tokens use the formula:
 *  `b_0 * b_1 = (s / 2)^2`
 * 
 * Where:
 *  `s` is the supply of LP tokens
 *  `b_i` is the balance at index `i`
 *  The 2 in `s / 2` follows from the fact that there are 2 tokens in the Well
 */
contract ConstantProduct2 is IWellFunction {
    using LibMath for uint;

    uint constant EXP_PRECISION = 1e18;

    /// @dev `s = (b_0 * b_1)^(1/2) * 2`
    function getLpTokenSupply(
        uint[] calldata balances,
        bytes calldata
    ) external override view returns (uint lpTokenSupply) {
        lpTokenSupply = (balances[0]*balances[1]*EXP_PRECISION).sqrt() * 2;
    }

    /// @dev `b_j = (s / 2)^2 / b_{i | i != j}`
    function getBalance(
        uint[] calldata balances,
        uint j,
        uint lpTokenSupply,
        bytes calldata
    ) external override pure returns (uint balance) {
        balance = uint((lpTokenSupply / 2) ** 2) / EXP_PRECISION;
        balance = (balance - 1) / balances[j == 1 ? 0 : 1] + 1; // Round
    }

    function name() external override pure returns (string memory) {
        return "Constant Product";
    }

    function symbol() external override pure returns (string memory) {
        return "CP";
    }
}