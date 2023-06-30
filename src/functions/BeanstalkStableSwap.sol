// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IBeanstalkWellFunction} from "src/interfaces/IBeanstalkWellFunction.sol";
import {LibMath} from "src/libraries/LibMath.sol";
import {SafeMath} from "oz/utils/math/SafeMath.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IBeanstalkA} from "src/interfaces/beanstalk/IBeanstalkA.sol";

/**
 * @author Publius, Brean
 * @title Gas efficient StableSwap pricing function for Wells with 2 tokens.
 * developed by solidly. 
 * @dev features an variable A parameter, queried from a beanstalk A param 
 * 
 * Stableswap Wells with 2 tokens use the formula:
 *  `4 * A * (b_0+b_1) + D = 4 * A * D + D^3/(4 * b_0 * b_1)`
 *
 * Where:
 *  `A` is the Amplication parameter. 
 *  `D` is the supply of LP tokens
 *  `b_i` is the reserve at index `i`
 */
contract BeanstalkStableSwap is IBeanstalkWellFunction {
    using LibMath for uint256;
    using SafeMath for uint256;

    // 2 token Pool. 
    uint256 constant N = 2;

    // A precision
    uint256 constant A_PRECISION = 100;
    
    // Precision that all pools tokens will be converted to.
    uint256 constant POOL_PRECISION_DECIMALS = 18;

    // Maximum A parameter. 
    uint256 constant MAX_A = 10000 * A_PRECISION;

    uint256 constant PRECISION = 1e18;

    // Beanstalk
    IBeanstalkA BEANSTALK = IBeanstalkA(0xC1E088fC1323b20BCBee9bd1B9fC9546db5624C5);
    

    // Errors
    error InvalidAParameter(uint256);
    error InvalidTokens();
    error InvalidTokenDecimals(uint256);

    /**
     * This Well function requires 3 parameters from wellFunctionData:
     * 0: Failsafe A parameter
     * 1: tkn0 address
     * 2: tkn1 address
     * 
     * @dev The StableSwap curve assumes that both tokens use the same decimals (max 1e18).
     * tkn0 and tkn1 is used to call decimals() on the tokens to scale to 1e18.
     * For example, USDC and BEAN has 6 decimals (TKX_SCALAR = 1e12),
     * while DAI has 18 decimals (TKX_SCALAR = 1).
     * 
     * The failsafe A parameter is used when the beanstalk A parameter is not available.
     */
    struct WellFunctionData {
        uint256 a;
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
        uint256[] memory reserves,
        bytes calldata _wellFunctionData
    ) public view override returns (uint256 lpTokenSupply) {
        (
            , 
            uint256 Ann,
            uint256[2] memory precisionMultipliers
        ) = verifyWellFunctionData(_wellFunctionData);

        
        uint256 sumReserves = reserves[0] * precisionMultipliers[0] + reserves[1] * precisionMultipliers[1];
        if(sumReserves == 0) return 0;
        lpTokenSupply = sumReserves;

        // wtf is this bullshit
        for(uint256 i = 0; i < 255; i++){
            uint256 dP = lpTokenSupply;
            // If division by 0, this will be borked: only withdrawal will work. And that is good
            dP = dP.mul(lpTokenSupply).div(reserves[0].mul(precisionMultipliers[0]).mul(N));
            dP = dP.mul(lpTokenSupply).div(reserves[1].mul(precisionMultipliers[1]).mul(N));
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
            if (lpTokenSupply > prevReserves){
                if(lpTokenSupply - prevReserves <= 1) return lpTokenSupply;
            }
            else {
                if(prevReserves - lpTokenSupply <= 1) return lpTokenSupply;
            }
        }
    }

    function getPrice(
        uint256[] calldata reserves,
        uint256 j,
        uint256 lpTokenSupply,
        bytes calldata _wellFunctionData
    ) external view returns (uint256) {
        (, uint256 Ann, uint256[2] memory precisionMultipliers) = verifyWellFunctionData(_wellFunctionData);
        uint256 c = lpTokenSupply;
        uint256 i = j == 1 ? 0 : 1;
        c = c.mul(lpTokenSupply).div(reserves[i].mul(precisionMultipliers[i]).mul(N));
        c = c.mul(lpTokenSupply).mul(A_PRECISION).div(Ann.mul(N));

        uint256 b = reserves[i].mul(
                precisionMultipliers[i]
            ).add(lpTokenSupply.mul(A_PRECISION).div(Ann));
        uint256 yPrev;
        uint256 y = lpTokenSupply;  
        for (uint256 k = 0; k < 256; i++) {
            yPrev = y;
            y = y.mul(y).add(c).div(y.mul(2).add(b).sub(lpTokenSupply));
            if(y > yPrev){
                if(y - yPrev <= 1) return y.div(precisionMultipliers[j]);
            } else {
                if(yPrev - y <= 1) return y.div(precisionMultipliers[j]);
            }
        }
        revert("Approximation did not converge");
    }


    /**
     * @notice Calculate x[i] if one reduces D from being calculated for xp to D
     * Done by solving quadratic equation iteratively.
     * x_1**2 + x_1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
     * x_1**2 + b*x_1 = c
     * x_1 = (x_1**2 + c) / (2*x_1 + b)
     */
    function calcReserve(
        uint256[] calldata reserves,
        uint256 j,
        uint256 lpTokenSupply,
        bytes calldata _wellFunctionData
    ) public view override returns (uint256 reserve) {
        (
            , 
            uint256 Ann,
            uint256[2] memory precisionMultipliers
        ) = verifyWellFunctionData(_wellFunctionData);
        require(j < N);
        uint256 c = lpTokenSupply;
        uint256 sumReserves;
        uint256 prevReserve; 
        sumReserves = j == 0 ? reserves[1].mul(precisionMultipliers[1]) : reserves[0].mul(precisionMultipliers[0]);
        c = c.mul(lpTokenSupply).div(sumReserves.mul(N));
        c = c.mul(lpTokenSupply).mul(A_PRECISION).div(Ann.mul(N));
        uint256 b = 
            sumReserves.add(
                lpTokenSupply.mul(A_PRECISION).div(Ann)
            );
        reserve = lpTokenSupply;

        for(uint256 i; i < 255; ++i){
            prevReserve = reserve;
            reserve = 
                reserve
                    .mul(reserve)
                    .add(c)
                    .div(
                        reserve
                            .mul(2)
                            .add(b)
                            .sub(lpTokenSupply)
                        );
            // Equality with the precision of 1
            // safeMath not needed due to conditional.
            if(reserve > prevReserve){
                if(reserve - prevReserve <= 1) return reserve.div(precisionMultipliers[j]);
            } else {
                if(prevReserve - reserve <= 1) return reserve.div(precisionMultipliers[j]);
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
        uint256 lpTokenAmount,
        uint256[] calldata reserves,
        uint256 lpTokenSupply,
        bytes calldata _wellFunctionData
    ) external view returns (uint256[] memory underlyingAmounts) {
        ( , , uint256[2] memory precisionMultipliers) = verifyWellFunctionData(_wellFunctionData);
        underlyingAmounts = new uint256[](2);
        // overflow cannot occur as lpTokenAmount could not be calculated.
        underlyingAmounts[0] = lpTokenAmount * reserves[0].mul(precisionMultipliers[0]) / lpTokenSupply;
        underlyingAmounts[1] = lpTokenAmount * reserves[1].mul(precisionMultipliers[1]) / lpTokenSupply;
    }

    function name() external pure override returns (string memory) {
        return "StableSwap";
    }

    function symbol() external pure override returns (string memory) {
        return "SS2";
    }

    


    /**
     * TODO: for deltaB minting
     * `ratios` here refer to the virtual price of the non-bean asset.
     * (precision 1e18).
     */
    function calcReserveAtRatioSwap(
        uint256[] calldata reserves,
        uint256 j,
        uint256[] calldata ratios,
        bytes calldata data
    ) external view returns (uint256 reserve){
        uint256[] memory _reserves = new uint256[](2);
        _reserves[0] = reserves[0].mul(ratios[0]).div(PRECISION);
        _reserves[1] = reserves[1].mul(ratios[1]).div(PRECISION);
        // uint256 oldD = calcLpTokenSupply(reserves, data) / 2;
        uint256 newD = calcLpTokenSupply(_reserves, data);
        return newD / 2;
    }

    // TODO: for converts 
    // `ratios` here refer to the virtual price of the non-bean asset 
    // high level: calc the reserve via adding or removing liq given some reserves, to target ratio.
    // 
    function calcReserveAtRatioLiquidity(
        uint256[] calldata reserves,
        uint256 j,
        uint256[] calldata ratios,
        bytes calldata
    ) external pure returns (uint256 reserve){
        uint256 i = j == 1 ? 0 : 1;
        reserve = reserves[i] * ratios[j] / ratios[i];
    }

    function getBeanstalkA() public pure returns (uint256 a) {
        return IBeanstalkA(0xC1E088fC1323b20BCBee9bd1B9fC9546db5624C5).getBeanstalkA();
    }
    function getBeanstalkAnn() public pure returns (uint256 a) {
        return getBeanstalkA() * N * N;
    }

    // TODO: implement. 
    function getVirtualPrice() public pure returns (uint256 price) {
        price = 1.01 * 1e18;
    }

    function verifyWellFunctionData(
        bytes memory data
    ) public view returns (
        uint256 a, 
        uint256 Ann,
        uint256[2] memory precisionMultipliers
    ){
        WellFunctionData memory wfd = abi.decode(data, (WellFunctionData));
        
        // try to get the beanstalk A. 
        // if it fails, use the failsafe A stored in well function data.
        try BEANSTALK.getBeanstalkA() returns (uint256 _a) {
            a = _a;
        } catch  {
            a = wfd.a;
        }
        if(wfd.tkn0 == address(0) || wfd.tkn1 == address(0)) revert InvalidTokens();
        uint8 token0Dec = IERC20(wfd.tkn0).decimals();
        uint8 token1Dec = IERC20(wfd.tkn0).decimals();

        if(token0Dec > 18) revert InvalidTokenDecimals(token0Dec); 
        if(token1Dec > 18) revert InvalidTokenDecimals(token1Dec); 

        Ann = a * N * N * A_PRECISION;
        precisionMultipliers[0] = 10 ** (POOL_PRECISION_DECIMALS - uint256(token0Dec));
        precisionMultipliers[1] = 10 ** (POOL_PRECISION_DECIMALS - uint256(token0Dec));
    }

}
