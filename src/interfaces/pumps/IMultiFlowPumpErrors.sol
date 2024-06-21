// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title IMultiFlowPumpErrors defines the errors for the MultiFlowPump.
 * @dev The errors are separated into a different interface as not all Pump
 * implementations may share the same errors.
 */
interface IMultiFlowPumpErrors {
    error NotInitialized();

    error NoTimePassed();

    error TooManyTokens();
}
