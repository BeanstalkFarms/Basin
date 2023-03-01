/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "src/interfaces/IWellFunction.sol";
import "src/libraries/LibMath.sol";

/**
 * @author Publius
 * @title Gas efficient Stable Swap pricing function for Wells with 2 tokens.
 * 
 * Stable Swap Wells with 2 tokens use the formula:
 *  `b_0^a * b_1 + b_0 * b_1^a = 2 * (s / 2)^(a+1)`
 * 
 * Where:
 *  `s` is the supply of LP tokens
 *  `b_i` is the reserve at index `i`
 *  The 2 in `s / 2` follows from the fact that there are 2 tokens in the Well
 */
contract StableSwap2 is IWellFunction {
    using LibMath for uint;

    uint constant EXP_PRECISION = 1e18;

    uint private a;

    constructor(uint _a) {
        a = _a;
    }

    /// @dev `s = ((b_0^a * b_1 + b_0 * b_1^a) / 2)^(1/(a+1)) * 2`
    function calcLpTokenSupply(
        uint[] calldata reserves,
        bytes calldata
    ) external override view returns (uint lpTokenSupply) {
        uint _a = reserves[0] * reserves[1] * EXP_PRECISION;
        uint _b = (reserves[0] ** (a - 1)) * EXP_PRECISION + (reserves[1] ** (a - 1)) * EXP_PRECISION;
        lpTokenSupply = (_a * _b / EXP_PRECISION / 2).nthRoot(a + 1) * 2;
    }

    function calcReserve(
        uint[] calldata reserves,
        uint j,
        uint lpTokenSupply,
        bytes calldata
    ) external override view returns (uint reserve) {
    }

    function name() external override pure returns (string memory) {
        return "Stable Swap";
    }

    function symbol() external override pure returns (string memory) {
        return "SS";
    }
}