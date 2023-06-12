// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

/**
 * @title IGeoEmaAndCumSmaPumpErrors defines the errors for the GeoEmaAndCumSmaPump.
 * @dev Because not all Pumps may share the same errors, the errors are defined in a
 * seperate interface.
 */
interface IGeoEmaAndCumSmaPumpErrors {
    error NotInitialized();

    error NoTimePassed();

    error InvalidMaxPercentDecreaseArgument(bytes16 maxPercentDecrease);

    error InvalidAArgument(bytes16 a);
}
