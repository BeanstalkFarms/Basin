/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

/**
 * @author Publius
 * @title Lib Math contains math operations
 **/
library LibMath {

    /**
     * @notice computes the nth root of a given number
     * @param a The number to compute the root of
     * @param n The root to compute
     * @return root The nth root of a
     * @dev TODO: more testing - https://ethereum.stackexchange.com/questions/38468/calculate-the-nth-root-of-an-arbitrary-uint-using-solidity
     * @dev https://en.wikipedia.org/wiki/Nth_root_algorithm
     */
    function nthRoot(uint a, uint n) internal pure returns (uint root) {
        assert (n > 1);
        if (n == 2) return sqrt(a); // shortcut for square root
        // The scale factor is a crude way to turn everything into integer calcs.
        // Actually do ((10 ^ n) * x) ^ (1/n)
        uint a0 = 10 ** n * a;

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
     * @return root The square root of x
     * @dev 
     * This function is based on the Babylonian method of computing square roots
     * https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
     * Implementation from: https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol#L11
     */
    function sqrt(uint a) internal pure returns (uint root) {
        uint z = (a + 1) / 2;
        root = a;
        while (z < root) {
            root = z;
            z = (a / z + z) / 2;
        }
    }
}