// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {LibMath} from "src/libraries/LibMath.sol";
import {SafeMath} from "oz/utils/math/SafeMath.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

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
 */
contract StableSwap2 is IWellFunction {
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

    // Errors
    error InvalidAParameter(uint256);
    error InvalidTokens();
    error InvalidTokenDecimals(uint256);

    /**
     * This Well function requires 3 parameters from wellFunctionData:
     * 1: A parameter 
     * 2: tkn0 address
     * 3: tkn1 address
     * 
     * @dev The StableSwap curve assumes that both tokens use the same decimals (max 1e18).
     * tkn0 and tkn1 is used to call decimals() on the tokens to scale to 1e18.
     * For example, USDC and BEAN has 6 decimals (TKX_SCALAR = 1e12),
     * while DAI has 18 decimals (TKX_SCALAR = 1).
     */
    struct WellFunctionData {
        uint256 a; // A parameter
        address tkn0;
        address tkn1;
    }

    /**
     * D invariant calculation in non-overflowing integer operations iteratively
     * A * sum(x_i) * n**n + D = A * D * n**n + D**(n+1) / (n**n * prod(x_i))
     * 
     * Converging solution:
     * D[j+1] = (4 * A * sum(b_i) - (D[j] ** 3) / (4 * prod(b_i))) / (4 * A - 1)
     */
    function calcLpTokenSupply(
        uint[] memory reserves,
        bytes calldata _wellFunctionData
    ) public view override returns (uint lpTokenSupply) {
        (, uint256 Ann,uint256[2] memory precisions) = decodeWFData(_wellFunctionData);
        reserves = getScaledReserves(reserves, precisions);
        
        uint256 sumReserves = reserves[0] + reserves[1];
        if(sumReserves == 0) return 0;
        lpTokenSupply = sumReserves;

        for(uint i = 0; i < 255; i++){
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
                    Ann.sub(A_PRECISION).mul(lpTokenSupply)
                    .div(A_PRECISION)
                    .add(N.add(1).mul(dP))
                );
            // Equality with the precision of 1
            if (lpTokenSupply > prevReserves){
                if(lpTokenSupply - prevReserves <= 1) return lpTokenSupply;
            }
            else {
                if(prevReserves - lpTokenSupply <= 1) return lpTokenSupply;
            }
        }
    }

    /**
     * @notice Calculate x[i] if one reduces D from being calculated for xp to D
     * Done by solving quadratic equation iteratively.
     * x_1**2 + x_1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
     * x_1**2 + b*x_1 = c
     * x_1 = (x_1**2 + c) / (2*x_1 + b)
     */
    function calcReserve(
        uint[] memory reserves,
        uint j,
        uint lpTokenSupply,
        bytes calldata _wellFunctionData
    ) external view override returns (uint reserve) {
        (, uint256 Ann, uint256[2] memory precisions) = decodeWFData(_wellFunctionData);
        reserves = getScaledReserves(reserves, precisions);

        require(j < N);
        uint256 c = lpTokenSupply;
        uint256 sumReserves;
        uint256 prevReserve; 
        sumReserves = j == 0 ? reserves[1] : reserves[0];
        c = c.mul(lpTokenSupply).div(sumReserves.mul(N));
        c = c.mul(lpTokenSupply).mul(A_PRECISION).div(Ann.mul(N));
        uint256 b = 
            sumReserves.add(
                lpTokenSupply.mul(A_PRECISION).div(Ann)
            );
        reserve = lpTokenSupply;

        for(uint i; i < 255; ++i){
            prevReserve = reserve;
            reserve = 
                reserve
                    .mul(reserve)
                    .add(c)
                    .div(reserve.mul(2).add(b).sub(lpTokenSupply));
            // Equality with the precision of 1
            // safeMath not needed due to conditional.
            if(reserve > prevReserve){
                if(reserve - prevReserve <= 1) return reserve;
            } else {
                if(prevReserve - reserve <= 1) return reserve;
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
        bytes calldata _wellFunctionData
    ) external view returns (uint[] memory underlyingAmounts) {
        ( , ,uint256[2] memory precisions) = decodeWFData(_wellFunctionData);
        reserves = getScaledReserves(reserves, precisions);

        underlyingAmounts = new uint[](2);
        // overflow cannot occur as lpTokenAmount could not be calculated.
        underlyingAmounts[0] = lpTokenAmount * reserves[0] / lpTokenSupply;
        underlyingAmounts[1] = lpTokenAmount * reserves[1] / lpTokenSupply;
    }

    function name() external pure override returns (string memory) {
        return "StableSwap";
    }

    function symbol() external pure override returns (string memory) {
        return "SS2";
    }

    function decodeWFData(
        bytes memory data
    ) public virtual view returns (
        uint256 a, 
        uint256 Ann,
        uint256[2] memory precisions
    ){
        WellFunctionData memory wfd = abi.decode(data, (WellFunctionData));
        a = wfd.a;
        if (a == 0) revert InvalidAParameter(a);
        if(wfd.tkn0 == address(0) || wfd.tkn1 == address(0)) revert InvalidTokens();
        if(IERC20(wfd.tkn0).decimals() > 18) revert InvalidTokenDecimals(IERC20(wfd.tkn0).decimals()); 
        Ann = a * N * N * A_PRECISION;
        precisions[0] = 10 ** (POOL_PRECISION_DECIMALS - uint256(IERC20(wfd.tkn0).decimals()));
        precisions[1] = 10 ** (POOL_PRECISION_DECIMALS - uint256(IERC20(wfd.tkn1).decimals()));
    }

    function getScaledReserves(
        uint[] memory reserves,
        uint256[2] memory precisions
    ) internal pure returns (uint[] memory) {
        reserves[0] = reserves[0].mul(precisions[0]);
        reserves[1] = reserves[1].mul(precisions[1]);
        return reserves;
    }
}
