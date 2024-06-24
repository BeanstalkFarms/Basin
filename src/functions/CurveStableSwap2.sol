// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IBeanstalkWellFunction, IMultiFlowPumpWellFunction} from "src/interfaces/IBeanstalkWellFunction.sol";
import {LibMath} from "src/libraries/LibMath.sol";
import {SafeMath} from "oz/utils/math/SafeMath.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import "forge-std/console.sol";

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
contract CurveStableSwap2 is IBeanstalkWellFunction {
    using LibMath for uint;
    using SafeMath for uint;

    // 2 token Pool.
    uint constant N = 2;

    // A precision
    uint constant A_PRECISION = 100;

    // Precision that all pools tokens will be converted to.
    uint constant POOL_PRECISION_DECIMALS = 18;

    // Maximum A parameter.
    uint constant MAX_A = 10000 * A_PRECISION;

    // Calc Rate Precision.
    uint256 constant CALC_RATE_PRECISION = 1e24;

    //
    uint256 MIN_TOKEN_DECIMALS = 10;

    // Errors
    error InvalidAParameter(uint256);
    error InvalidTokens();
    error InvalidTokenDecimals(uint256);

    /**
     * The CurveStableSwap Well Function fetches the following data from the well:
     * 1: A parameter
     * 2: token0 address
     * 3: token1 address
     */
    struct WellFunctionData {
        uint256 a;
        address token0;
        address token1;
    }

    struct DeltaB {
        uint256 pegBeans;
        int256 currentBeans;
        int256 deltaBToPeg;
        int256 deltaPriceToTarget;
        int256 deltaPriceToPeg;
        int256 estDeltaB;
        uint256 targetPrice;
        uint256 poolPrice;
    }

    /**
     * @notice Calculate the amount of LP tokens minted when adding liquidity.
     * D invariant calculation in non-overflowing integer operations iteratively
     * A * sum(x_i) * n**n + D = A * D * n**n + D**(n+1) / (n**n * prod(x_i))
     *
     * Converging solution:
     * D[j+1] = (4 * A * sum(b_i) - (D[j] ** 3) / (4 * prod(b_i))) / (4 * A - 1)
     */
    function calcLpTokenSupply(
        uint[] memory reserves,
        bytes calldata data
    ) public view returns (uint lpTokenSupply) {
        (uint256 Ann, uint256[] memory precisions) = decodeWFData(data);
        console.log(precisions[0], precisions[1]);
        reserves = getScaledReserves(reserves, precisions);

        uint256 sumReserves = reserves[0] + reserves[1];
        if (sumReserves == 0) return 0;
        lpTokenSupply = sumReserves;

        for (uint i = 0; i < 255; i++) {
            uint256 dP = lpTokenSupply;
            // If division by 0, this will be borked: only withdrawal will work. And that is good
            dP = dP.mul(lpTokenSupply).div(reserves[0].mul(N));
            dP = dP.mul(lpTokenSupply).div(reserves[1].mul(N));
            uint256 prevReserves = lpTokenSupply;
            lpTokenSupply = Ann
                .mul(sumReserves)
                .div(A_PRECISION)
                .add(dP.mul(N))
                .mul(lpTokenSupply)
                .div(
                    Ann
                        .sub(A_PRECISION)
                        .mul(lpTokenSupply)
                        .div(A_PRECISION)
                        .add(N.add(1).mul(dP))
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
        uint[] memory reserves,
        uint j,
        uint lpTokenSupply,
        bytes calldata data
    ) public view returns (uint reserve) {
        (uint256 Ann, uint256[] memory precisions) = decodeWFData(data);
        reserves = getScaledReserves(reserves, precisions);

        // avoid stack too deep errors.
        (uint256 c, uint256 b) = getBandC(
            Ann,
            lpTokenSupply,
            j == 0 ? reserves[1] : reserves[0]
        );
        reserve = lpTokenSupply;
        uint256 prevReserve;

        for (uint i; i < 255; ++i) {
            prevReserve = reserve;
            reserve = _calcReserve(reserve, b, c, lpTokenSupply);
            // Equality with the precision of 1
            // scale reserve down to original precision
            if (reserve > prevReserve) {
                if (reserve - prevReserve <= 1)
                    return reserve.div(precisions[j]);
            } else {
                if (prevReserve - reserve <= 1)
                    return reserve.div(precisions[j]);
            }
        }
        revert("did not find convergence");
    }

    /**
     * @notice Defines a proportional relationship between the supply of LP tokens
     * and the amount of each underlying token for a two-token Well.
     * @dev When removing `s` LP tokens with a Well with `S` LP token supply, the user
     * recieves `s * b_i / S` of each underlying token.
     * reserves are scaled as needed based on tknXScalar
     */
    function calcLPTokenUnderlying(
        uint lpTokenAmount,
        uint[] memory reserves,
        uint lpTokenSupply,
        bytes calldata
    ) external view returns (uint[] memory underlyingAmounts) {
        underlyingAmounts = new uint[](2);
        underlyingAmounts[0] = (lpTokenAmount * reserves[0]) / lpTokenSupply;
        underlyingAmounts[1] = (lpTokenAmount * reserves[1]) / lpTokenSupply;
    }

    /**
     * @inheritdoc IMultiFlowPumpWellFunction
     * @dev when the reserves are equal, the summation of the reserves
     * is equivalent to the token supply of the Well. The LP token supply is calculated from
     * `reserves`, and is scaled based on `ratios`.
     */
    function calcReserveAtRatioSwap(
        uint256[] memory reserves,
        uint256 j,
        uint256[] memory ratios,
        bytes calldata data
    ) external view returns (uint256 reserve) {
        DeltaB memory db;

        uint256 i = j == 1 ? 0 : 1;
        // scale reserves to 18 decimals.
        uint256 lpTokenSupply = calcLpTokenSupply(reserves, data);
        console.log("lpTokenSupply:", lpTokenSupply);
        // inital guess
        db.currentBeans = int256(reserves[j]);
        console.log("db.currentBeans");
        console.logInt(db.currentBeans);
        db.pegBeans = lpTokenSupply / 2;
        console.log("db.pegBeans");
        console.log(db.pegBeans);
        db.deltaBToPeg = int256(db.pegBeans) - int256(reserves[j]);
        console.log("db.deltaBToPeg");
        console.logInt(db.deltaBToPeg);

        uint256 prevPrice;
        uint256 x;
        uint256 x2;

        // fetch target and pool prices.
        // scale ratio by precision:
        ratios[0] = ratios[0] * CALC_RATE_PRECISION;
        ratios[1] = ratios[1] * CALC_RATE_PRECISION;
        console.log("ratios[0]", ratios[0]);
        console.log("ratios[1]", ratios[1]);

        db.targetPrice = calcRate(ratios, i, j, data);
        console.log("db.targetPrice", db.targetPrice);
        console.log("reserve0", reserves[0]);
        console.log("reserve1", reserves[1]);
        db.poolPrice = calcRate(reserves, i, j, data);
        console.log("db.poolPrice", db.poolPrice);

        for (uint k; k < 2; k++) {
            db.deltaPriceToTarget =
                int256(db.targetPrice) -
                int256(db.poolPrice);
            console.log("deltaPriceToTarget");
            console.logInt(db.deltaPriceToTarget);
            db.deltaPriceToPeg = 1e18 - int256(db.poolPrice);
            console.log("deltaPriceToPeg");

            console.logInt(db.deltaPriceToPeg);
            console.log("reserve0----", reserves[j]);
            console.log("pegBeans----", db.pegBeans);
            db.deltaBToPeg = int256(db.pegBeans) - int256(reserves[j]);
            console.log("deltaBToPeg");
            console.logInt(db.deltaBToPeg);
            console.log("estDeltaB");
            console.logInt(db.estDeltaB);

            if (db.deltaPriceToPeg != 0) {
                db.estDeltaB =
                    (db.deltaBToPeg *
                        int256(
                            (db.deltaPriceToTarget * 1e18) / db.deltaPriceToPeg
                        )) /
                    1e18;
            } else {
                db.estDeltaB = 0;
            }
            console.log("estDeltaB");
            console.logInt(db.estDeltaB);
            x = uint256(int256(reserves[j]) + db.estDeltaB);
            console.log("-----reserve0----", reserves[0]);
            console.log("-----reserve1----", reserves[1]);
            console.log(i);
            x2 = calcReserve(reserves, i, lpTokenSupply, data);
            console.log("x", x, "x2", x2);
            reserves[j] = x;
            reserves[i] = x2;
            prevPrice = db.poolPrice;
            db.poolPrice = calcRate(reserves, i, j, data);
            if (prevPrice > db.poolPrice) {
                if (prevPrice - db.poolPrice <= 1) break;
            } else if (db.poolPrice - prevPrice <= 1) break;
        }
        return reserves[j];
    }

    /**
     * @inheritdoc IMultiFlowPumpWellFunction
     */
    function calcRate(
        uint256[] memory reserves,
        uint256 i,
        uint256 j,
        bytes calldata data
    ) public view returns (uint256 rate) {
        // console.log("reserves[j]", reserves[j]);
        // console.log("reserves[i]", reserves[i]);
        uint256[] memory _reserves = new uint256[](2);
        _reserves[0] = reserves[0];
        _reserves[1] = reserves[1];
        uint256 lpTokenSupply = calcLpTokenSupply(reserves, data);
        // console.log("reserves[j]", reserves[j]);
        // console.log("reserves[i]", reserves[i]);
        // console.log("_reserves[j]", _reserves[j]);
        // console.log("_reserves[i]", _reserves[i]);
        // add the precision of opposite token to the reserve.
        (uint256 padding, uint256 divPadding) = getPadding(
            _reserves,
            i,
            j,
            data
        );
        // console.log("padding", padding);
        // console.log("reserves[j]", _reserves[j]);
        _reserves[j] = _reserves[j] + padding;
        // console.log("reserves[j]", _reserves[j]);
        // console.log("reserves[i]", _reserves[i]);
        uint256 oldReserve = _reserves[i];
        uint256 newReserve = calcReserve(_reserves, i, lpTokenSupply, data);
        // console.log("oldReserve", oldReserve);
        // console.log("newReserve", newReserve);
        // console.log("diff", oldReserve - newReserve);
        uint256 tokenIDecimal = getTokenDecimal(i, data);
        uint256 tokenJDecimal = getTokenDecimal(j, data);
        // console.log("Check", (18 + tokenIDecimal - tokenJDecimal));
        // console.log("divPadding", divPadding);

        rate =
            ((oldReserve - newReserve) *
                (10 ** (18 + tokenIDecimal - tokenJDecimal))) /
            divPadding;
    }

    /**
     * @inheritdoc IBeanstalkWellFunction
     */
    function calcReserveAtRatioLiquidity(
        uint256[] calldata reserves,
        uint256 j,
        uint256[] calldata ratios,
        bytes calldata
    ) external pure returns (uint256 reserve) {
        uint256 i = j == 1 ? 0 : 1;
        reserve = (reserves[i] * ratios[j]) / ratios[i];
    }

    function name() external pure returns (string memory) {
        return "StableSwap";
    }

    function symbol() external pure returns (string memory) {
        return "SS2";
    }

    /**
     * @notice decodes the data encoded in the well.
     * @return Ann (A parameter * n^2)
     * @return precisions the value used to scale each token such that
     * each token has 18 decimals.
     */
    function decodeWFData(
        bytes memory data
    ) public view virtual returns (uint256 Ann, uint256[] memory precisions) {
        WellFunctionData memory wfd = abi.decode(data, (WellFunctionData));
        if (wfd.a == 0) revert InvalidAParameter(wfd.a);
        if (wfd.token0 == address(0) || wfd.token1 == address(0))
            revert InvalidTokens();

        uint8 token0Decimals = IERC20(wfd.token0).decimals();
        uint8 token1Decimals = IERC20(wfd.token1).decimals();

        if (token0Decimals > 18) revert InvalidTokenDecimals(token0Decimals);
        if (token1Decimals > 18) revert InvalidTokenDecimals(token1Decimals);

        Ann = wfd.a * N * N * A_PRECISION;

        precisions = new uint256[](2);
        precisions[0] =
            10 ** (POOL_PRECISION_DECIMALS - uint256(token0Decimals));
        precisions[1] =
            10 ** (POOL_PRECISION_DECIMALS - uint256(token1Decimals));
    }

    function getTokenDecimal(
        uint256 i,
        bytes memory data
    ) internal view returns (uint256 decimals) {
        WellFunctionData memory wfd = abi.decode(data, (WellFunctionData));
        return
            i == 0
                ? IERC20(wfd.token0).decimals()
                : IERC20(wfd.token1).decimals();
    }

    function getPadding(
        uint256[] memory reserves,
        uint256 i,
        uint256 j,
        bytes memory data
    ) internal view returns (uint256 padding, uint256 divPadding) {
        uint256 k = reserves[i] < reserves[j] ? i : j;

        uint256 numDigits = getNumDigits(reserves, k);

        // Set the slippage error equal to the precision.
        padding = numDigits / 2;

        uint256 tokenIDecimal = getTokenDecimal(i, data);
        uint256 tokenJDecimal = getTokenDecimal(j, data);

        // console.log("tokenIDecimalI", tokenIDecimal);
        // console.log("tokenJDecimalJ", tokenJDecimal);

        // console.log("paddings", padding);
        if (tokenJDecimal > tokenIDecimal) {
            divPadding = 10 ** padding;
            // console.log("paddings", padding);
            padding = padding + tokenJDecimal - tokenIDecimal;
        } else {
            divPadding = 10 ** (padding + (tokenIDecimal - tokenJDecimal));
        }
        // console.log("paddings", padding);

        if (padding > tokenJDecimal) {
            padding = tokenJDecimal;
        }
        // console.log("paddings", padding);
        padding = 10 ** padding;

        // 10000001/10000000

        // 10000000

        // 100001/99999 = 1.0000200002 -> 4 zeroes.
        // 1000001/99999 = 10.0001100011 -> 4 zeroes.
        // 10000001/99999 = 100.0010100101 -> 4 zeroes
        // 100001/999999 = 0.1000011 -> 4 zeros.
        // 100001/9999999 = 0.010000101 -> 4 zeroes
        // 100001/99999999 = 0.00100001001 -> 4 zeroes
    }

    function getNumDigits(
        uint256[] memory reserves,
        uint256 i
    ) internal pure returns (uint256 numDigits) {
        numDigits = 0;
        uint256 reserve = reserves[i];
        while (reserve != 0) {
            reserve /= 10;
            numDigits++;
        }
    }

    /**
     * @notice scale `reserves` by `precision`.
     * @dev this sets both reserves to 18 decimals.
     */
    function getScaledReserves(
        uint[] memory reserves,
        uint256[] memory precisions
    ) internal pure returns (uint[] memory) {
        reserves[0] = reserves[0].mul(precisions[0]);
        reserves[1] = reserves[1].mul(precisions[1]);
        return reserves;
    }

    function _calcReserve(
        uint256 reserve,
        uint256 b,
        uint256 c,
        uint256 lpTokenSupply
    ) private pure returns (uint256) {
        return
            reserve.mul(reserve).add(c).div(
                reserve.mul(2).add(b).sub(lpTokenSupply)
            );
    }

    function getBandC(
        uint256 Ann,
        uint256 lpTokenSupply,
        uint256 reserves
    ) private pure returns (uint256 c, uint256 b) {
        c = lpTokenSupply
            .mul(lpTokenSupply)
            .div(reserves.mul(N))
            .mul(lpTokenSupply)
            .mul(A_PRECISION)
            .div(Ann.mul(N));
        b = reserves.add(lpTokenSupply.mul(A_PRECISION).div(Ann));
    }
}
