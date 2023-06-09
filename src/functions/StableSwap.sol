// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ProportionalLPToken2} from "src/functions/ProportionalLPToken2.sol";
import {LibMath} from "src/libraries/LibMath.sol";

/**
 * @author Publius
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

    uint constant EXP_PRECISION = 1e12;
    uint constant A_PRECISION = 100;

    // A paramater
    uint constant A = 1;
    // 2 token Pool. 
    uint constant N = 2;
    // Ann is used everywhere `shrug` 
    uint constant Ann = A * N;

    /**
     * D invariant calculation in non-overflowing integer operations iteratively
     * A * sum(x_i) * n**n + D = A * D * n**n + D**(n+1) / (n**n * prod(x_i))
     * 
     * Converging solution:
     * D[j+1] = (4 * A * sum(b_i) - (D[j] ** 3) / (4 * prod(b_i))) / (4 * A - 1)
     * D[2] = (4 * A * sum(b_i) - (D[1] ** 3) / (4 * prod(b_i))) / (4 * A - 1)
     */
    function calcLpTokenSupply(
        uint[] calldata reserves,
        bytes calldata
    ) external pure override returns (uint d) {
        uint256 s = 0; 
        uint256 Dprev = 0;

        s = reserves[0] + reserves[1];
        if(s == 0) return 0;
        d = s;

        // wtf is this bullshit
        for(uint i; i < 255; i++){
            uint256 d_p = d;
            for(uint j; j < N; j++){
                // If division by 0, this will be borked: only withdrawal will work. And that is good
                d_p = d_p * d / (reserves[j] * N);
            }
            Dprev = d;
            d = (Ann * s / A_PRECISION + d_p * N) * 
                d / (
                    (Ann - A_PRECISION) * d / 
                    A_PRECISION + (N + 1) * d_p
                );
            // Equality with the precision of 1
            if (d > Dprev){
                if(d - Dprev <= 1) return d;
            }
            else {
                if(Dprev - d <= 1) return d;
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
    ) external pure override returns (uint reserve) {
        require(j < N);
        uint256 c = lpTokenSupply;
        uint256 s;
        uint256 _x;
        uint256 y_prev; 


        for(uint i; i < N; ++i){
            if(i != j){
                _x = reserves[j];
            } else {
                continue;
            }
            s +=_x;
            c = c * lpTokenSupply / (_x * N);
        }
        c = c * lpTokenSupply * A /(Ann * N);
        uint256 b = s + lpTokenSupply * A_PRECISION / Ann;
        reserve = lpTokenSupply;

        for(uint i; i < 255; ++i){
            y_prev = reserve;
            reserve = (reserve*reserve + c) / (2 * reserve + b - lpTokenSupply);
            // Equality with the precision of 1
            if(reserve > y_prev){
                if(reserve - y_prev <= 1) return reserve;
            } else {
                if(y_prev - reserve <= 1) return reserve;
            }
        }
        revert("did not find convergence");        
    }

    function name() external pure override returns (string memory) {
        return "Stableswap";
    }

    function symbol() external pure override returns (string memory) {
        return "SS";
    }

    function cube(uint256 reserve) private pure returns (uint256) {
        return reserve * reserve * reserve;
    }
}
