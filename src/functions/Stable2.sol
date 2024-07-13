// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IBeanstalkWellFunction, IMultiFlowPumpWellFunction} from "src/interfaces/IBeanstalkWellFunction.sol";
import {ILookupTable} from "src/interfaces/ILookupTable.sol";
import {ProportionalLPToken2} from "src/functions/ProportionalLPToken2.sol";
import {LibMath} from "src/libraries/LibMath.sol";
import {SafeMath} from "oz/utils/math/SafeMath.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {console} from "forge-std/console.sol";
/**
 * @author Brean
 * @title Gas efficient StableSwap pricing function for Wells with 2 tokens.
 * developed by curve.
 *
 * Stableswap Wells with 2 tokens use the formula:
 *  `4 * A * (b_0+b_1) + D = 4 * A * D + D^3/(4 * b_0 * b_1)`
 *
 * Where:
 *  `A` is the Amplication parameter.
 *  `D` is the supply of LP tokens
 *  `b_i` is the reserve at index `i`
 *
 * @dev Limited to tokens with a maximum of 18 decimals.
 */

contract Stable2 is ProportionalLPToken2, IBeanstalkWellFunction {
    struct PriceData {
        uint256 targetPrice;
        uint256 currentPrice;
        uint256 maxStepSize;
        ILookupTable.PriceData lutData;
    }

    using LibMath for uint256;
    using SafeMath for uint256;

    // 2 token Pool.
    uint256 constant N = 2;

    // A precision
    uint256 constant A_PRECISION = 100;

    // price precision.
    uint256 constant PRICE_PRECISION = 1e6;

    // price threshold. more accurate pricing requires a lower threshold,
    // at the cost of higher execution costs.
    uint256 constant PRICE_THRESHOLD = 100; // 0.001%

    address immutable lookupTable;
    uint256 immutable a;

    // Errors
    error InvalidTokenDecimals();
    error InvalidLUT();

    // Due to the complexity of `calcReserveAtRatioLiquidity` and `calcReserveAtRatioSwap`,
    // a LUT is used to reduce the complexity of the calculations on chain.
    // the lookup table contract implements 3 functions:
    // 1. getRatiosFromPriceLiquidity(uint256) -> PriceData memory
    // 2. getRatiosFromPriceSwap(uint256) -> PriceData memory
    // 3. getAParameter() -> uint256
    // Lookup tables are a function of the A parameter.
    constructor(address lut) {
        if (lut == address(0)) revert InvalidLUT();
        lookupTable = lut;
        a = ILookupTable(lut).getAParameter();
    }

    /**
     * @notice Calculate the amount of lp tokens given reserves.
     * D invariant calculation in non-overflowing integer operations iteratively
     * A * sum(x_i) * n**n + D = A * D * n**n + D**(n+1) / (n**n * prod(x_i))
     *
     * Converging solution:
     * D[j+1] = (4 * A * sum(b_i) - (D[j] ** 3) / (4 * prod(b_i))) / (4 * A - 1)
     */
    function calcLpTokenSupply(
        uint256[] memory reserves,
        bytes memory data
    ) public view returns (uint256 lpTokenSupply) {
        if (reserves[0] == 0 && reserves[1] == 0) return 0;
        uint256[] memory decimals = decodeWellData(data);
        // scale reserves to 18 decimals.
        uint256[] memory scaledReserves = getScaledReserves(reserves, decimals);

        uint256 Ann = a * N * N * A_PRECISION;

        uint256 sumReserves = scaledReserves[0] + scaledReserves[1];
        if (sumReserves == 0) return 0;
        lpTokenSupply = sumReserves;
        for (uint256 i = 0; i < 255; i++) {
            uint256 dP = lpTokenSupply;
            // If division by 0, this will be borked: only withdrawal will work. And that is good
            dP = dP.mul(lpTokenSupply).div(scaledReserves[0].mul(N));
            dP = dP.mul(lpTokenSupply).div(scaledReserves[1].mul(N));
            uint256 prevReserves = lpTokenSupply;
            lpTokenSupply = Ann.mul(sumReserves).div(A_PRECISION).add(dP.mul(N)).mul(lpTokenSupply).div(
                Ann.sub(A_PRECISION).mul(lpTokenSupply).div(A_PRECISION).add(N.add(1).mul(dP))
            );
            // Equality with the precision of 1
            if (lpTokenSupply > prevReserves) {
                if (lpTokenSupply - prevReserves <= 1) return lpTokenSupply;
            } else {
                if (prevReserves - lpTokenSupply <= 1) return lpTokenSupply;
            }
        }
    }

    /**
     * @notice Calculate x[i] if one reduces D from being calculated for reserves to D
     * Done by solving quadratic equation iteratively.
     * x_1**2 + x_1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
     * x_1**2 + b*x_1 = c
     * x_1 = (x_1**2 + c) / (2*x_1 + b)
     * @dev This function has a precision of +/- 1,
     * which may round in favor of the well or the user.
     */
    function calcReserve(
        uint256[] memory reserves,
        uint256 j,
        uint256 lpTokenSupply,
        bytes memory data
    ) public view returns (uint256 reserve) {
        uint256[] memory decimals = decodeWellData(data);
        uint256[] memory scaledReserves = getScaledReserves(reserves, decimals);

        // avoid stack too deep errors.
        (uint256 c, uint256 b) =
            getBandC(a * N * N * A_PRECISION, lpTokenSupply, j == 0 ? scaledReserves[1] : scaledReserves[0]);
        reserve = lpTokenSupply;
        uint256 prevReserve;

        for (uint256 i; i < 255; ++i) {
            prevReserve = reserve;
            reserve = _calcReserve(reserve, b, c, lpTokenSupply);
            // Equality with the precision of 1
            // scale reserve down to original precision
            if (reserve > prevReserve) {
                if (reserve - prevReserve <= 1) {
                    return reserve.div(10 ** (18 - decimals[j]));
                }
            } else {
                if (prevReserve - reserve <= 1) {
                    return reserve.div(10 ** (18 - decimals[j]));
                }
            }
        }
        revert("did not find convergence");
    }

    /**
     * @inheritdoc IMultiFlowPumpWellFunction
     * @dev `calcReserveAtRatioSwap` fetches the closes approximate ratios from the target price,
     * and performs newtons method in order to converge into a reserve.
     */
    function calcReserveAtRatioSwap(
        uint256[] memory reserves,
        uint256 j,
        uint256[] memory ratios,
        bytes calldata data
    ) external view returns (uint256 reserve) {
        uint256 i = j == 1 ? 0 : 1;
        // scale reserves and ratios:
        uint256[] memory decimals = decodeWellData(data);
        uint256[] memory scaledReserves = getScaledReserves(reserves, decimals);

        PriceData memory pd;

        {
            uint256[] memory scaledRatios = getScaledReserves(ratios, decimals);
            // calc target price with 6 decimal precision:
            pd.targetPrice = scaledRatios[1] * PRICE_PRECISION / scaledRatios[0];
        }

        // get ratios and price from the closest highest and lowest price from targetPrice:
        pd.lutData = ILookupTable(lookupTable).getRatiosFromPriceSwap(pd.targetPrice);

        // perform an initial update on the reserves, such that `calcRate(reserves, i, j, data) == pd.lutData.lowPrice.

        // calculate lp token supply:
        uint256 lpTokenSupply = calcLpTokenSupply(scaledReserves, abi.encode(18, 18));

        // lpTokenSupply / 2 gives the reserves at parity:
        uint256 parityReserve = lpTokenSupply / 2;

        // update `scaledReserves`.
        scaledReserves[0] = parityReserve * pd.lutData.lowPriceI / pd.lutData.precision;
        scaledReserves[1] = parityReserve * pd.lutData.lowPriceJ / pd.lutData.precision;

        // calculate max step size:
        pd.maxStepSize = (pd.lutData.highPriceJ - pd.lutData.lowPriceJ) / pd.lutData.highPriceJ * reserves[j];

        // initialize currentPrice:
        pd.currentPrice = pd.lutData.lowPrice;

        for (uint256 k; k < 255; k++) {
            // scale stepSize proporitional to distance from price:
            uint256 stepSize =
                pd.maxStepSize * (pd.targetPrice - pd.currentPrice) / (pd.lutData.highPrice - pd.lutData.lowPrice);
            // increment reserve by stepSize:
            scaledReserves[j] = reserves[j] + stepSize;
            // calculate scaledReserve[i]:
            scaledReserves[i] = calcReserve(scaledReserves, i, lpTokenSupply, abi.encode(18, 18));

            // check if new price is within 1 of target price:
            if (pd.currentPrice > pd.targetPrice) {
                if (pd.currentPrice - pd.targetPrice <= PRICE_THRESHOLD) return scaledReserves[j] / (10 ** decimals[j]);
            } else {
                if (pd.targetPrice - pd.currentPrice <= PRICE_THRESHOLD) return scaledReserves[j] / (10 ** decimals[j]);
            }

            // calc currentPrice:
            pd.currentPrice = calcRate(reserves, i, j, data);
        }
    }

    /**
     * @inheritdoc IMultiFlowPumpWellFunction
     * @dev Returns a rate with  decimal precision.
     * Requires a minimum scaled reserves of 1e12.
     * 6 decimals was chosen as higher decimals would require a higher minimum scaled reserve,
     * which is prohibtive for large value tokens.
     */
    function calcRate(
        uint256[] memory reserves,
        uint256 i,
        uint256 j,
        bytes memory data
    ) public view returns (uint256 rate) {
        uint256[] memory decimals = decodeWellData(data);
        uint256[] memory scaledReserves = getScaledReserves(reserves, decimals);

        // calc lp token supply (note: `scaledReserves` is scaled up, and does not require bytes).
        uint256 lpTokenSupply = calcLpTokenSupply(scaledReserves, abi.encode(18, 18));

        // add 1e6 to reserves:
        scaledReserves[j] += PRICE_PRECISION;

        // calculate new reserve 1:
        uint256 new_reserve1 = calcReserve(scaledReserves, i, lpTokenSupply, abi.encode(18, 18));
        rate = (scaledReserves[i] - new_reserve1);
    }

    /**
     * @inheritdoc IBeanstalkWellFunction
     * @notice Calculates the amount of each reserve token underlying a given amount of LP tokens.
     * @dev `calcReserveAtRatioLiquidity` fetches the closest approximate ratios from the target price, and
     * perform an neutonian-estimation to calculate the reserves.
     */
    function calcReserveAtRatioLiquidity(
        uint256[] calldata reserves,
        uint256 j,
        uint256[] calldata ratios,
        bytes calldata data
    ) external view returns (uint256 reserve) {
        uint256 i = j == 1 ? 0 : 1;
        // scale reserves and ratios:
        uint256[] memory decimals = decodeWellData(data);
        uint256[] memory scaledReserves = getScaledReserves(reserves, decimals);

        PriceData memory pd;
        {
            uint256[] memory scaledRatios = getScaledReserves(ratios, decimals);
            // calc target price with 6 decimal precision:
            pd.targetPrice = scaledRatios[j] * PRICE_PRECISION / scaledRatios[i];
        }

        // get ratios and price from the closest highest and lowest price from targetPrice:
        pd.lutData = ILookupTable(lookupTable).getRatiosFromPriceLiquidity(pd.targetPrice);

        // update scaledReserve[j] based on lowPrice:
        // console.log("scaledReserve[j] b4", scaledReserves[j]);
        scaledReserves[j] = scaledReserves[i] * pd.lutData.lowPriceJ / pd.lutData.precision;
        // console.log("scaledReserve[j] afta", scaledReserves[j]);

        // calculatde max step size:
        // console.log("pd.lutData.highPriceJ", pd.lutData.highPriceJ);
        // console.log("pd.lutData.lowPriceJ", pd.lutData.lowPriceJ);

        pd.maxStepSize = scaledReserves[j] * (pd.lutData.highPriceJ - pd.lutData.lowPriceJ) / pd.lutData.highPriceJ;
        // console.log("pd.maxStepSize", pd.maxStepSize);

        // calc currentPrice:
        // console.log("scaledReserve[j]", scaledReserves[j]);
        // console.log("scaledReserve[i]", scaledReserves[i]);
        pd.currentPrice = calcRate(scaledReserves, j, i, abi.encode(18, 18));
        // console.log("initial currentPrice", pd.currentPrice);

        for (uint256 k; k < 255; k++) {
            // console.log("----------------", k);
            // scale stepSize proporitional to distance from price:
            // console.log("pd.targetPrice", pd.targetPrice);
            // console.log("pd.currentPrice before stepping", pd.currentPrice);
            uint256 stepSize =
                pd.maxStepSize * (pd.targetPrice - pd.currentPrice) / (pd.lutData.highPrice - pd.lutData.lowPrice);
            // console.log("stepSize", stepSize);
            // increment reserve by stepSize:
            // console.log("scaledReserves[j] b4", scaledReserves[j]);
            scaledReserves[j] = scaledReserves[j] + stepSize;
            // console.log("scaledReserves[i] af", scaledReserves[i]);
            // console.log("scaledReserves[j] af", scaledReserves[j]);
            // calculate new price from reserves:
            // todo: j and i needs to be switched. Current LUT has it inverted
            pd.currentPrice = calcRate(scaledReserves, j, i, abi.encode(18, 18));

            // check if new price is within PRICE_THRESHOLD:
            // console.log("pd.currentPrice after stepping", pd.currentPrice);
            // console.log("target price:", pd.targetPrice);
            if (pd.currentPrice > pd.targetPrice) {
                if (pd.currentPrice - pd.targetPrice <= PRICE_THRESHOLD) {
                    return scaledReserves[j] / (10 ** (18 - decimals[j]));
                }
            } else {
                if (pd.targetPrice - pd.currentPrice <= PRICE_THRESHOLD) {
                    return scaledReserves[j] / (10 ** (18 - decimals[j]));
                }
            }
        }
    }

    function name() external pure returns (string memory) {
        return "Stable2";
    }

    function symbol() external pure returns (string memory) {
        return "S2";
    }

    /**
     * @notice decodes the data encoded in the well.
     * @return decimals an array of the decimals of the tokens in the well.
     */
    function decodeWellData(bytes memory data) public view virtual returns (uint256[] memory decimals) {
        (uint256 decimal0, uint256 decimal1) = abi.decode(data, (uint256, uint256));

        // if well data returns 0, assume 18 decimals.
        if (decimal0 == 0) {
            decimal0 = 18;
        }
        if (decimal0 == 0) {
            decimal1 = 18;
        }
        if (decimal0 > 18 || decimal1 > 18) revert InvalidTokenDecimals();

        decimals = new uint256[](2);
        decimals[0] = decimal0;
        decimals[1] = decimal1;
    }

    /**
     * @notice scale `reserves` by `precision`.
     * @dev this sets both reserves to 18 decimals.
     */
    function getScaledReserves(
        uint256[] memory reserves,
        uint256[] memory decimals
    ) internal pure returns (uint256[] memory scaledReserves) {
        scaledReserves = new uint256[](2);
        scaledReserves[0] = reserves[0] * 10 ** (18 - decimals[0]);
        scaledReserves[1] = reserves[1] * 10 ** (18 - decimals[1]);
    }

    function _calcReserve(
        uint256 reserve,
        uint256 b,
        uint256 c,
        uint256 lpTokenSupply
    ) private pure returns (uint256) {
        return reserve.mul(reserve).add(c).div(reserve.mul(2).add(b).sub(lpTokenSupply));
    }

    function getBandC(
        uint256 Ann,
        uint256 lpTokenSupply,
        uint256 reserves
    ) private pure returns (uint256 c, uint256 b) {
        c = lpTokenSupply.mul(lpTokenSupply).div(reserves.mul(N)).mul(lpTokenSupply).mul(A_PRECISION).div(Ann.mul(N));
        b = reserves.add(lpTokenSupply.mul(A_PRECISION).div(Ann));
    }
}
