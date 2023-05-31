// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title Lib Math contains math operations
 */
library LibMath {

    /**
     * @param a numerator
     * @param b denominator
     * @dev Division, rounded up
     */
    function roundUpDiv(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        return (a - 1) / b + 1;
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
        // Equivalent to "i % 2 == 0" but cheaper.
        if (n & 1 == 0) {
            if (n == 2) return sqrt(a); // shortcut for square root
            if (n == 4) return sqrt(sqrt(a));
            if (n == 8) return sqrt(sqrt(sqrt(a)));
            if (n == 16) return sqrt(sqrt(sqrt(sqrt(a))));
        }
        // The scale factor is a crude way to turn everything into integer calcs.
        // Actually do ((10 ^ n) * a) ^ (1/n)
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
     * @return z The square root of a
     * @dev
     * This function is based on the Babylonian method of computing square roots
     * https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
     * Implementation from: https://github.com/Gaussian-Process/solidity-sqrt/blob/main/src/FixedPointMathLib.sol
     * based on https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol
     */

    function sqrt(uint a) internal pure returns (uint z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := a // We start y at a, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if a >= 256, then y >= 256.
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

            // Goal was to get z*z*y within a small factor of a. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if a < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= a < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or a < 256.
            // Correctness can be checked exhaustively for a < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(a), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(a, z)))
            z := shr(1, add(z, div(a, z)))
            z := shr(1, add(z, div(a, z)))
            z := shr(1, add(z, div(a, z)))
            z := shr(1, add(z, div(a, z)))
            z := shr(1, add(z, div(a, z)))
            z := shr(1, add(z, div(a, z)))

            // If a+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(a)) and ceil(sqrt(a)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(a, z), z))
        }
    }
}
