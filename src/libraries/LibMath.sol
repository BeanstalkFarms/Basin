// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title Lib Math contains math operations
 */
import {SafeMath} from "oz/utils/math/SafeMath.sol";

library LibMath {
    error PRBMath_MulDiv_Overflow(uint x, uint y, uint denominator);

    /**
     * @param a numerator
     * @param b denominator
     * @dev Division, round to nearest integer (AKA round-half-up).
     *
     * Skip explicit checks for division by zero as Solidity will natively revert.
     *
     * Implementation:
     * https://github.com/cryptoticket/openzeppelin-solidity/blob/04e62a7a1ece4832bee411ca5de024d2ce0b15e6/contracts/math/RoundedDivMath.sol#L31
     */
    function roundedDiv(uint a, uint b) internal pure returns (uint) {
        uint halfB = (b % 2 == 0) ? (b / 2) : (b / 2 + 1);
        return (a % b >= halfB) ? (a / b + 1) : (a / b);
    }

    /**
     * @notice Computes the `n`th root of a number `a` using the Newton--Raphson method.
     * @param a The number to compute the root of
     * @param n The root to compute
     * @return root The `n`th root of `a`
     * @dev TODO: more testing - https://ethereum.stackexchange.com/questions
     * /38468/calculate-the-nth-root-of-an-arbitrary-uint-using-solidity
     * https://en.wikipedia.org/wiki/Nth_root_algorithm
     * This is used in {ConstantProduct.Sol}, where the number of tokens are
     * restricted to 16. even roots are much cheaper to compute than uneven,
     * thus we recursively call sqrt().
     *
     */
    function nthRoot(uint a, uint n) internal pure returns (uint root) {
        assert(n > 1);
        if (a == 0) return 0;
        if (n % 2 == 0) {
            if (n == 2) return sqrt(a); // shortcut for square root
            if (n == 4) return sqrt(sqrt(a));
            if (n == 8) return sqrt(sqrt(sqrt(a)));
            if (n == 16) return sqrt(sqrt(sqrt(sqrt(a))));
        }
        // The scale factor is a crude way to turn everything into integer calcs.
        // Actually do ((10 ^ n) * x) ^ (1/n)
        uint a0 = (10 ** n) * a;

        uint xNew = 10;
        uint x;
        while (xNew != x) {
            x = xNew;
            uint t0 = x ** (n - 1);
            if (x * t0 > a0) {
                xNew = x - (x - a0 / t0) / n;
            } else {
                xNew = x + (a0 / t0 - x) / n;
            }
        }

        root = (xNew + 5) / 10;
    }

    /**
     * @notice computes the square root of a given number
     * @param a The number to compute the square root of
     * @return z The square root of x
     * @dev
     * This function is based on the Babylonian method of computing square roots
     * https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
     * Implementation from: https://github.com/Gaussian-Process/solidity-sqrt/blob/main/src/FixedPointMathLib.sol
     * based on https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol
     */

    function sqrt(uint a) internal pure returns (uint z) {
        assembly {
            // This segment is to get a reasonable initial estimate for the Babylonian method.
            // If the initial estimate is bad, the number of correct bits increases ~linearly
            // each iteration instead of ~quadratically.
            // The idea is to get z*z*y within a small factor of x.
            // More iterations here gets y in a tighter range. Currently, we will have
            // y in [256, 256*2^16). We ensure y>= 256 so that the relative difference
            // between y and y+1 is small. If x < 256 this is not possible, but those cases
            // are easy enough to verify exhaustively.
            z := 181 // The 'correct' value is 1, but this saves a multiply later
            let y := a
            // Note that we check y>= 2^(k + 8) but shift right by k bits each branch,
            // this is to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }
            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8),
            // and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of x, or about 20bps.

            // The estimate sqrt(x) = (181/1024) * (x+1) is off by a factor of ~2.83 both when x=1
            // and when x = 256 or 1/256. In the worst case, this needs seven Babylonian iterations.
            z := shr(18, mul(z, add(y, 65536))) // A multiply is saved from the initial z := 181

            // Run the Babylonian method seven times. This should be enough given initial estimate.
            // Possibly with a quadratic/cubic polynomial above we could get 4-6.
            z := shr(1, add(z, div(a, z)))
            z := shr(1, add(z, div(a, z)))
            z := shr(1, add(z, div(a, z)))
            z := shr(1, add(z, div(a, z)))
            z := shr(1, add(z, div(a, z)))
            z := shr(1, add(z, div(a, z)))
            z := shr(1, add(z, div(a, z)))

            // See https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division.
            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This check ensures we return floor.
            // The solmate implementation assigns zRoundDown := div(x, z) first, but
            // since this case is rare, we choose to save gas on the assignment and
            // repeat division in the rare case.
            // If you don't care whether floor or ceil is returned, you can skip this.
            if lt(div(a, z), z) { z := div(a, z) }
        }
    }
}
