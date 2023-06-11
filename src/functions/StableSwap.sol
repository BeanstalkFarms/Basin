// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ProportionalLPToken2} from "src/functions/ProportionalLPToken2.sol";
import {LibMath} from "src/libraries/LibMath.sol";
import {SafeMath} from "oz/utils/math/SafeMath.sol";

/**
 * @author Publius, Brean
 * @title Gas efficient StableSwap pricing function for Wells with 2 tokens.
 * developed by solidly. 
 * 
 * Stableswap Wells with 2 tokens use the formula:
 *  `4 * A * (b_0+b_1) + D = 4 * A * D + D^3/(4 * b_0 * b_1)`
 *
 * Where:
 *  `A` is the Amplication parameter. 
 *  `D` is the supply of LP tokens
 *  `b_i` is the reserve at index `i`
 */
contract StableSwap is ProportionalLPToken2 {
    using LibMath for uint;
    using SafeMath for uint;

    uint constant A_PRECISION = 100;

    // A parameter
    uint public immutable a;
    // 2 token Pool. 
    uint constant N = 2;
    // Ann is used everywhere `shrug` 
    // uint256 constant Ann = A * N * A_PRECISION;

    constructor(uint _a) {
      a = _a;
    }
    /**
     * D invariant calculation in non-overflowing integer operations iteratively
     * A * sum(x_i) * n**n + D = A * D * n**n + D**(n+1) / (n**n * prod(x_i))
     * 
     * Converging solution:
     * D[j+1] = (4 * A * sum(b_i) - (D[j] ** 3) / (4 * prod(b_i))) / (4 * A - 1)
     */
    function calcLpTokenSupply(
        uint[] calldata reserves,
        bytes calldata
    ) external view override returns (uint lpTokenSupply) {
        uint256 sumReserves = reserves[0] + reserves[1];
        uint256 prevD;
        if(sumReserves == 0) return 0;
       
        lpTokenSupply = sumReserves;
        uint256 Ann = a * N * N * A_PRECISION;
        // wtf is this bullshit
        for(uint i = 0; i < 255; i++){
            uint256 dP = lpTokenSupply;
            for(uint j = 0; j < N; j++){
                // If division by 0, this will be borked: only withdrawal will work. And that is good
                dP = dP.mul(lpTokenSupply).div(reserves[j].mul(N));
            }
            prevD = lpTokenSupply;
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
            
            if (lpTokenSupply > prevD){
                if(lpTokenSupply - prevD <= 1) return lpTokenSupply;
            }
            else {
                if(prevD - lpTokenSupply <= 1) return lpTokenSupply;
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
        uint[] calldata reserves,
        uint j,
        uint lpTokenSupply,
        bytes calldata
    ) external view override returns (uint reserve) {
        require(j < N);
        uint256 c = lpTokenSupply;
        uint256 sumReserves;
        uint256 _x;
        uint256 y_prev; 
        uint256 Ann = a * N * N * A_PRECISION;


        for(uint i; i < N; ++i){
            if(i != j){
                _x = reserves[i];
            } else {
                continue;
            }
            sumReserves = sumReserves.add(_x);
            c = c.mul(lpTokenSupply).div(_x.mul(N));
        }
        c = c.mul(lpTokenSupply).mul(A_PRECISION).div(Ann.mul(N));
        uint256 b = 
            sumReserves.add(
                lpTokenSupply.mul(A_PRECISION).div(Ann)
            );
        reserve = lpTokenSupply;

        for(uint i; i < 255; ++i){
            y_prev = reserve;
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
            if(reserve > y_prev){
                if(reserve.sub(y_prev) <= 1) return reserve;
            } else {
                if(y_prev.sub(reserve) <= 1) return reserve;
            }
        }
        revert("did not find convergence");        
    }

    function name() external pure override returns (string memory) {
        return "StableSwap";
    }

    function symbol() external pure override returns (string memory) {
        return "SS";
    }

    function cube(uint256 reserve) private pure returns (uint256) {
        return reserve * reserve * reserve;
    }
}
