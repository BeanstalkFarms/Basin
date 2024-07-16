// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IBeanstalkWellFunction, IMultiFlowPumpWellFunction} from "src/interfaces/IBeanstalkWellFunction.sol";
import {ILookupTable} from "src/interfaces/ILookupTable.sol";
import {ProportionalLPToken2} from "src/functions/ProportionalLPToken2.sol";
import {LibMath} from "src/libraries/LibMath.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {console} from "forge-std/console.sol";
/**
 * @author Brean, DeadManWalking
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
 * The Stable2 Well Function takes in the following data from the well:
 * - Token[0,1] decimals
 * Data is encoded as `(uint256[])`.
 * if no data is encoded, defaults to ([18,18]).
 */

contract Stable2 is ProportionalLPToken2, IBeanstalkWellFunction {
    struct PriceData {
        uint256 targetPrice;
        uint256 currentPrice;
        uint256 maxStepSize;
        ILookupTable.PriceData lutData;
    }

    using LibMath for uint256;

    // 2 token Pool.
    uint256 constant N = 2;

    // A precision
    uint256 constant A_PRECISION = 100;

    // price precision.
    uint256 constant PRICE_PRECISION = 1e6;

    // price threshold. more accurate pricing requires a lower threshold,
    // at the cost of higher execution costs.
    uint256 constant PRICE_THRESHOLD = 100; // 0.01%;

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
        // scale reserves to 18 decimals.
        uint256[] memory scaledReserves;
        if (data.length == 0) {
            scaledReserves = reserves;
        } else {
            (scaledReserves,) = getScaledReservesAndDecimals(reserves, data);
        }

        uint256 Ann = a * N * N * A_PRECISION;

        uint256 sumReserves = scaledReserves[0] + scaledReserves[1];
        if (sumReserves == 0) return 0;
        lpTokenSupply = sumReserves;
        for (uint256 i = 0; i < 255; i++) {
            uint256 dP = lpTokenSupply;
            // If division by 0, this will be borked: only withdrawal will work. And that is good
            dP = dP * lpTokenSupply / (scaledReserves[0] * N);
            dP = dP * lpTokenSupply / (scaledReserves[1] * N);
            uint256 prevReserves = lpTokenSupply;
            lpTokenSupply = (Ann * sumReserves / A_PRECISION + (dP * N)) * lpTokenSupply
                / (((Ann - A_PRECISION) * lpTokenSupply / A_PRECISION) + ((N + 1) * dP));
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
        uint256[] memory scaledReserves;
        uint256[] memory decimals;
        if (data.length == 0) {
            scaledReserves = reserves;
            decimals = new uint256[](2);
            decimals[0] = 18;
            decimals[1] = 18;
        } else {
            (scaledReserves, decimals) = getScaledReservesAndDecimals(reserves, data);
        }

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
                    return reserve / (10 ** (18 - decimals[j]));
                }
            } else {
                if (prevReserve - reserve <= 1) {
                    return reserve / (10 ** (18 - decimals[j]));
                }
            }
        }
        revert("did not find convergence");
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
        uint256[] memory scaledReserves;
        if (data.length == 0) {
            scaledReserves = reserves;
        } else {
            (scaledReserves,) = getScaledReservesAndDecimals(reserves, data);
        }
        uint256 lpTokenSupply = calcLpTokenSupply(scaledReserves, new bytes(0));
        rate = _calcRate(scaledReserves, i, j, lpTokenSupply);
    }

    /**
     * @notice internal calcRate function.
     */
    function _calcRate(
        uint256[] memory reserves,
        uint256 i,
        uint256 j,
        uint256 lpTokenSupply
    ) internal view returns (uint256 rate) {
        // add 1e6 to reserves:
        uint256[] memory _reserves = new uint256[](2);
        _reserves[i] = reserves[i];
        _reserves[j] = reserves[j] + PRICE_PRECISION;

        // calculate rate:
        rate = _reserves[i] - calcReserve(_reserves, i, lpTokenSupply, new bytes(0));
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
        (uint256[] memory scaledReserves, uint256[] memory decimals) = getScaledReservesAndDecimals(reserves, data);

        PriceData memory pd;
        (uint256[] memory scaledRatios,) = getScaledReservesAndDecimals(ratios, data);
        // calc target price with 6 decimal precision:
        pd.targetPrice = scaledRatios[i] * PRICE_PRECISION / scaledRatios[j];

        // get ratios and price from the closest highest and lowest price from targetPrice:
        pd.lutData = ILookupTable(lookupTable).getRatiosFromPriceSwap(pd.targetPrice);

        // calculate lp token supply:
        uint256 lpTokenSupply = calcLpTokenSupply(scaledReserves, new bytes(0));

        // lpTokenSupply / 2 gives the reserves at parity:
        uint256 parityReserve = lpTokenSupply / 2;

        // update `scaledReserves` based on whether targetPrice is closer to low or high price:
        if (pd.lutData.highPrice - pd.targetPrice > pd.targetPrice - pd.lutData.lowPrice) {
            // targetPrice is closer to lowPrice.
            scaledReserves[i] = parityReserve * pd.lutData.lowPriceI / pd.lutData.precision;
            scaledReserves[j] = parityReserve * pd.lutData.lowPriceJ / pd.lutData.precision;
            // initialize currentPrice:
            pd.currentPrice = pd.lutData.lowPrice;
        } else {
            // targetPrice is closer to highPrice.
            scaledReserves[i] = parityReserve * pd.lutData.highPriceI / pd.lutData.precision;
            scaledReserves[j] = parityReserve * pd.lutData.highPriceJ / pd.lutData.precision;
            // initialize currentPrice:
            pd.currentPrice = pd.lutData.highPrice;
        }

        // calculate max step size:
        if (pd.lutData.lowPriceJ > pd.lutData.highPriceJ) {
            pd.maxStepSize = scaledReserves[j] * (pd.lutData.lowPriceJ - pd.lutData.highPriceJ) / pd.lutData.lowPriceJ;
        } else {
            pd.maxStepSize = scaledReserves[j] * (pd.lutData.highPriceJ - pd.lutData.lowPriceJ) / pd.lutData.highPriceJ;
        }

        for (uint256 k; k < 255; k++) {
            scaledReserves[j] = updateReserve(pd, scaledReserves[j]);

            // calculate scaledReserve[i]:
            scaledReserves[i] = calcReserve(scaledReserves, i, lpTokenSupply, new bytes(0));
            // calc currentPrice:
            pd.currentPrice = _calcRate(scaledReserves, i, j, lpTokenSupply);

            // check if new price is within 1 of target price:
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
        (uint256[] memory scaledReserves, uint256[] memory decimals) = getScaledReservesAndDecimals(reserves, data);

        PriceData memory pd;
        (uint256[] memory scaledRatios,) = getScaledReservesAndDecimals(ratios, data);
        // calc target price with 6 decimal precision:
        pd.targetPrice = scaledRatios[i] * PRICE_PRECISION / scaledRatios[j];

        // get ratios and price from the closest highest and lowest price from targetPrice:
        pd.lutData = ILookupTable(lookupTable).getRatiosFromPriceLiquidity(pd.targetPrice);

        // update scaledReserve[j] such that calcRate(scaledReserves, i, j) = low/high Price,
        // depending on which is closer to targetPrice.
        if (pd.lutData.highPrice - pd.targetPrice > pd.targetPrice - pd.lutData.lowPrice) {
            // targetPrice is closer to lowPrice.
            scaledReserves[j] = scaledReserves[i] * pd.lutData.lowPriceJ / pd.lutData.precision;

            // set current price to lowPrice.
            pd.currentPrice = pd.lutData.lowPrice;
        } else {
            // targetPrice is closer to highPrice.
            scaledReserves[j] = scaledReserves[i] * pd.lutData.highPriceJ / pd.lutData.precision;

            // set current price to highPrice.
            pd.currentPrice = pd.lutData.highPrice;
        }

        // calculate max step size:
        if (pd.lutData.lowPriceJ > pd.lutData.highPriceJ) {
            pd.maxStepSize = scaledReserves[j] * (pd.lutData.lowPriceJ - pd.lutData.highPriceJ) / pd.lutData.lowPriceJ;
        } else {
            pd.maxStepSize = scaledReserves[j] * (pd.lutData.highPriceJ - pd.lutData.lowPriceJ) / pd.lutData.highPriceJ;
        }
        for (uint256 k; k < 255; k++) {
            scaledReserves[j] = updateReserve(pd, scaledReserves[j]);
            // calculate new price from reserves:
            pd.currentPrice = calcRate(scaledReserves, i, j, new bytes(0));

            // check if new price is within PRICE_THRESHOLD:
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

    function name() external pure virtual returns (string memory) {
        return "Stable2";
    }

    function symbol() external pure virtual returns (string memory) {
        return "S2";
    }

    /**
     * @notice decodes the data encoded in the well.
     * @return decimals an array of the decimals of the tokens in the well.
     */
    function getDecimalsFromData(bytes memory data) public pure virtual returns (uint256[] memory decimals) {
        if (data.length == 0) {
            decimals = new uint256[](2);
            decimals[0] = 18;
            decimals[1] = 18;
        }
        (decimals) = abi.decode(data, (uint256[]));

        // if decimals returns 0, assume 18 decimals.
        for (uint256 i; i < 2; i++) {
            if (decimals[i] > 18) revert InvalidTokenDecimals();
        }
    }

    /**
     * @notice scale `reserves` by decimals encoded in `data`,
     * and scale `tokenIndex` reserve by `virtualPrice`.
     */
    function getScaledReservesAndDecimals(
        uint256[] memory reserves,
        bytes memory data
    ) internal pure virtual returns (uint256[] memory scaledReserves, uint256[] memory decimals) {
        decimals = getDecimalsFromData(data);
        scaledReserves = new uint256[](2);
        for (uint256 i; i < 2; i++) {
            scaledReserves[i] = reserves[i] * 10 ** (18 - decimals[i]);
        }
    }

    function _calcReserve(
        uint256 reserve,
        uint256 b,
        uint256 c,
        uint256 lpTokenSupply
    ) private pure returns (uint256) {
        return (reserve * reserve + c) / (reserve * 2 + b - lpTokenSupply);
    }

    function getBandC(
        uint256 Ann,
        uint256 lpTokenSupply,
        uint256 reserves
    ) private pure returns (uint256 c, uint256 b) {
        c = lpTokenSupply * lpTokenSupply / (reserves * N) * lpTokenSupply * A_PRECISION / (Ann * N);
        b = reserves + (lpTokenSupply * A_PRECISION / Ann);
    }

    /**
     * @notice calculates the step size, and returns the updated reserve.
     */
    function updateReserve(PriceData memory pd, uint256 reserve) internal pure returns (uint256) {
        if (pd.targetPrice > pd.currentPrice) {
            // if the targetPrice is greater than the currentPrice,
            // the reserve needs to be decremented to increase currentPrice.
            return reserve
                - pd.maxStepSize * (pd.targetPrice - pd.currentPrice) / (pd.lutData.highPrice - pd.lutData.lowPrice);
        } else {
            // if the targetPrice is less than the currentPrice,
            // the reserve needs to be incremented to decrease currentPrice.
            return reserve
                + pd.maxStepSize * (pd.currentPrice - pd.targetPrice) / (pd.lutData.highPrice - pd.lutData.lowPrice);
        }
    }
}
