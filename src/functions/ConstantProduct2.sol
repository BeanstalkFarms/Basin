// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IBeanstalkWellFunction} from "src/interfaces/IBeanstalkWellFunction.sol";
import {ProportionalLPToken2} from "src/functions/ProportionalLPToken2.sol";
import {LibMath} from "src/libraries/LibMath.sol";
import {Math} from "oz/utils/math/Math.sol";

/**
 * @title ConstantProduct2
 * @author Brendan
 * @notice Gas efficient Constant Product pricing function for Wells with 2 tokens.
 * @dev Constant Product Wells with 2 tokens use the formula:
 *  `b_0 * b_1 = s^2`
 *
 * Where:
 *  `s` is the supply of LP tokens
 *  `b_i` is the reserve at index `i`
 */
contract ConstantProduct2 is ProportionalLPToken2, IBeanstalkWellFunction {
    using Math for uint256;

    uint256 constant EXP_PRECISION = 1e12;
    uint256 constant CALC_RATE_PRECISION = 1e18;

    /**
     * @dev `s = (b_0 * b_1)^(1/2)`
     *
     * When does this function overflow?
     * ---------------------------------
     *
     * Let N be the length of the reserves array, and P be the precision multiplier
     * defined in `EXP_PRECISION`.
     *
     * Assuming all tokens in reserves are at their maximum value simultaneously,
     * this function will overflow when:
     *
     *  (10^X)^N * P >= MAX_UINT256 (~10^77)
     *  10^(X*N) >= 10^77/P
     *  (X*N)*ln(10) >= 77*ln(10) - ln(P)
     *
     *  ∴ X >= (1/N) * (77 - ln(P)/ln(10))
     *
     * ConstantProduct2 sets the constraints `N = 2` and `EXP_PRECISION = 1e12`,
     * resulting in an upper bound of X = 32.5.
     *
     * In other words, {calcLpTokenSupply} overflows if all reserves are simultaneously
     * >= 10^32.5, or about 100 trillion if tokens are measured to 18 decimal precision.
     *
     * The further apart the reserve values, the greater the loss of precision in the `sqrt` function.
     */
    function calcLpTokenSupply(
        uint256[] calldata reserves,
        bytes calldata
    ) external pure override returns (uint256 lpTokenSupply) {
        lpTokenSupply = (reserves[0] * reserves[1] * EXP_PRECISION).sqrt();
    }

    /// @dev `b_j = s^2 / b_{i | i != j}`
    /// @dev rounds up
    function calcReserve(
        uint256[] calldata reserves,
        uint256 j,
        uint256 lpTokenSupply,
        bytes calldata
    ) external pure override returns (uint256 reserve) {
        if (j >= 2) {
            revert InvalidJArgument();
        }
        // Note: potential optimization is to use unchecked math here
        reserve = lpTokenSupply ** 2;
        reserve = LibMath.roundUpDiv(reserve, reserves[j == 1 ? 0 : 1] * EXP_PRECISION);
    }

    function name() external pure override returns (string memory) {
        return "Constant Product 2";
    }

    function symbol() external pure override returns (string memory) {
        return "CP2";
    }

    /// @dev `b_j = (b_0 * b_1 * r_j / r_i)^(1/2)`
    /// Note: Always rounds down
    function calcReserveAtRatioSwap(
        uint256[] calldata reserves,
        uint256 j,
        uint256[] calldata ratios,
        bytes calldata
    ) external pure override returns (uint256 reserve) {
        uint256 i = j == 1 ? 0 : 1;
        // use 512 muldiv for last mul to avoid overflow
        reserve = (reserves[i] * reserves[j]).mulDiv(ratios[j], ratios[i]).sqrt();
    }

    /// @dev `b_j = b_i * r_j / r_i`
    /// Note: Always rounds down
    function calcReserveAtRatioLiquidity(
        uint256[] calldata reserves,
        uint256 j,
        uint256[] calldata ratios,
        bytes calldata
    ) external pure override returns (uint256 reserve) {
        uint256 i = j == 1 ? 0 : 1;
        reserve = reserves[i] * ratios[j] / ratios[i];
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
