/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity =0.8.17;
pragma experimental ABIEncoderV2;

/**
 * @title IPump provides an interface for a Pump, an on-chain oracle that is 
 * updated upon each interaction with a {IWell}.
 * @author Publius
 */
interface IPump {

    /**
     * @notice Attaches the Pump to a Well.
     * @param n The number of tokens in the Well
     * @param pumpData Pump data provided on every call
     * @dev Should be called by a Well during construction. See {Well-constructor}.
     * `msg.sender` should be assumed to be the Well address.
     */
    function attach(uint n, bytes calldata pumpData) external;

    /**
     * @notice Updates the Pump with the given balances.
     * @param balances The previous balances of the tokens in the Well.
     * @param pumpData Pump data provided on every call
     * @dev Pumps are updated every time a user swaps, adds liquidity, or
     * removes liquidity from a Well.
     */
    function update(uint[] calldata balances, bytes calldata pumpData) external;

    /**
     * @notice Reads Pump data related to an attached Well.
     * @param well The address of the Well
     * @param readData The data to be read by the Pump
     * @return data The data read from the Pump
     */
    function read(address well, bytes calldata readData) view external returns (bytes memory data);
} 