// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

/**
 * @title IPumpErrors defines the errors for Pumps.
 */
interface IPumpErrors {
    error NotInitialized();

    error NoTimePassed();

    error InvalidConstructorArgument(bytes16 maxPercentDecrease);
}
