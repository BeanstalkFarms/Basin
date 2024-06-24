// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// import {IWellFunction} from "src/interfaces/IWellFunction.sol";
// import {LibMath} from "src/libraries/LibMath.sol";
// import {SafeMath} from "oz/utils/math/SafeMath.sol";
// import {IERC20} from "forge-std/interfaces/IERC20.sol";

// /**
//  * @author Brean
//  * @title Gas efficient StableSwap pricing function for Wells with 2 tokens.
//  * developed by Solidly/Aerodome: https://github.com/aerodrome-finance/contracts
//  *
//  * Stableswap Wells with 2 tokens use the formula:
//  *  `d = (b_0^3 * b_1) + (b_0 ^ 3 + b_1)`
//  *
//  * Where:
//  *  `d` is the supply of LP tokens
//  *  `b_i` is the reserve at index `i`
//  */
// contract CurveStableSwap2 is IWellFunction {
//     using LibMath for uint;
//     using SafeMath for uint;

//     uint256 constant PRECISION = 1e18;

//     /**
//      * @notice Calculates the `j`th reserve given a list of `reserves` and `lpTokenSupply`.
//      * @param reserves A list of token reserves. The jth reserve will be ignored, but a placeholder must be provided.
//      * @param j The index of the reserve to solve for
//      * @param lpTokenSupply The supply of LP tokens
//      * @param data Extra Well function data provided on every call
//      * @return reserve The resulting reserve at the jth index
//      * @dev Should round up to ensure that Well reserves are marginally higher to enforce calcLpTokenSupply(...) >= totalSupply()
//      */
//     function calcReserve(
//         uint256[] memory reserves,
//         uint256 j,
//         uint256 lpTokenSupply,
//         bytes calldata data
//     ) external view returns (uint256 reserve);

//     /**
//      * @notice Gets the LP token supply given a list of reserves.
//      * @param reserves A list of token reserves
//      * @param data Extra Well function data provided on every call
//      * @return lpTokenSupply The resulting supply of LP tokens
//      * @dev Should round down to ensure so that the Well Token supply is marignally lower to enforce calcLpTokenSupply(...) >= totalSupply()
//      */
//     function calcLpTokenSupply(
//         uint256[] memory reserves,
//         bytes calldata data
//     ) external view returns (uint256 lpTokenSupply);

//     /**
//      * @notice Calculates the amount of each reserve token underlying a given amount of LP tokens.
//      * @param lpTokenAmount An amount of LP tokens
//      * @param reserves A list of token reserves
//      * @param lpTokenSupply The current supply of LP tokens
//      * @param data Extra Well function data provided on every call
//      * @return underlyingAmounts The amount of each reserve token that underlies the LP tokens
//      * @dev The constraint totalSupply() <= calcLPTokenSupply(...) must be held in the case where
//      * `lpTokenAmount` LP tokens are burned in exchanged for `underlyingAmounts`. If the constraint
//      * does not hold, then the Well Function is invalid.
//      */
//     function calcLPTokenUnderlying(
//         uint256 lpTokenAmount,
//         uint256[] memory reserves,
//         uint256 lpTokenSupply,
//         bytes calldata data
//     ) external view returns (uint256[] memory underlyingAmounts) {
//         // overflow cannot occur as lpTokenAmount could not be calculated.
//         underlyingAmounts[0] = (lpTokenAmount * reserves[0]) / lpTokenSupply;
//         underlyingAmounts[1] = (lpTokenAmount * reserves[1]) / lpTokenSupply;
//     };

//     /**
//      * @notice Calculates the `j` reserve such that `π_{i | i != j} (d reserves_j / d reserves_i) = π_{i | i != j}(ratios_j / ratios_i)`.
//      * assumes that reserve_j is being swapped for other reserves in the Well.
//      * @dev used by Beanstalk to calculate the deltaB every Season
//      * @param reserves The reserves of the Well
//      * @param j The index of the reserve to solve for
//      * @param ratios The ratios of reserves to solve for
//      * @param data Well function data provided on every call
//      * @return reserve The resulting reserve at the jth index
//      */
//     function calcReserveAtRatioSwap(
//         uint256[] calldata reserves,
//         uint256 j,
//         uint256[] calldata ratios,
//         bytes calldata data
//     ) external view returns (uint256 reserve);

//     /**
//      * @inheritdoc IMultiFlowPumpWellFunction
//      * @dev Implmentation from: https://github.com/aerodrome-finance/contracts/blob/main/contracts/Pool.sol#L460
//      */
//     function calcRate(
//         uint256[] calldata reserves,
//         uint256 i,
//         uint256 j,
//         bytes calldata data
//     ) external view returns (uint256 rate) {
//         uint256[] memory _reserves = reserves;
//         uint256 xy = _k(_reserves[0], _reserves[1]);
//         _reserves[0] = (_reserves[0] * PRECISION) / decimals0;
//         _reserves[1] = (_reserves[1] * PRECISION) / decimals1;
//         (uint256 reserveA, uint256 reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
//         amountIn = tokenIn == token0 ? (amountIn * PRECISION) / decimals0 : (amountIn * PRECISION) / decimals1;
//         uint256 y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
//         return (y * (tokenIn == token0 ? decimals1 : decimals0)) / PRECISION;
//     };

//      /**
//      * @notice Calculates the `j` reserve such that `π_{i | i != j} (d reserves_j / d reserves_i) = π_{i | i != j}(ratios_j / ratios_i)`.
//      * assumes that reserve_j is being added or removed in exchange for LP Tokens.
//      * @dev used by Beanstalk to calculate the max deltaB that can be converted in/out of a Well.
//      * @param reserves The reserves of the Well
//      * @param j The index of the reserve to solve for
//      * @param ratios The ratios of reserves to solve for
//      * @param data Well function data provided on every call
//      * @return reserve The resulting reserve at the jth index
//      */
//     function calcReserveAtRatioLiquidity(
//         uint256[] calldata reserves,
//         uint256 j,
//         uint256[] calldata ratios,
//         bytes calldata data
//     ) external view returns (uint256 reserve);

//     /**
//      * @notice returns k, based on the reserves of x/y.
//      * @param x the reserves of `x`
//      * @param y the reserves of `y`.
//      *
//      * @dev Implmentation from:
//      * https://github.com/aerodrome-finance/contracts/blob/main/contracts/Pool.sol#L315
//      */
//     function _k(uint256 x, uint256 y) internal view returns (uint256) {
//         uint256 _x = (x * PRECISION) / decimals0;
//         uint256 _y = (y * PRECISION) / decimals1;
//         uint256 _a = (_x * _y) / PRECISION;
//         uint256 _b = ((_x * _x) / PRECISION + (_y * _y) / PRECISION);
//         return (_a * _b) / PRECISION; // x3y+y3x >= k
//     }

//     function name() external pure override returns (string memory) {
//         return "Solidly-StableSwap";
//     }

//     function symbol() external pure override returns (string memory) {
//         return "SSS2";
//     }
// }
