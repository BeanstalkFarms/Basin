// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title Lib Math contains math operations
 */
library LibMath {
    /**
     * @param a numerator
     * @param b denominator
     * @dev Division, rounded up
     */
    function roundUpDiv(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function nthRoot(uint256 a, uint256 n) internal pure returns (uint256 root) {
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
        uint256 a0 = (10 ** n) * a;

        uint256 xNew = 10;
        uint256 x;
        while (xNew != x) {
            x = xNew;
            uint256 t0 = x ** (n - 1);
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

    function sqrt(uint256 a) internal pure returns (uint256 z) {
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

    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        unchecked {
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }
}
