/**
 * SPDX-License-Identifier: MIT
**/

pragma solidity =0.8.17;
pragma experimental ABIEncoderV2;

/**
 * @title IPump is the interface for the Pump contract
**/
interface IPump {

    /**
     * @notice attaches the pump to a well
     * @param n The number of tokens in the well
     * @param pumpData pump specific data
     * @dev 
     * Should be called by a Well on deployment.
     * `msg.sender` should be assumed to be the Well address.
     */
    function attach(uint n, bytes calldata pumpData) external;

    /**
     * @notice updates the pump with given data
     * @param balances The previous balances of the tokens in the well
     * @param pumpData pump specific data
     * @dev called everytime someone swaps, adds liquidity or removes liquidity from a well
     */
    function update(uint[] calldata balances, bytes calldata pumpData) external;

    /**
     * @notice reads the pump with given data
     * @param well The address of the well
     * @param data The data to be read by the pump
     * @return data The dats read from the pump
     */
    function read(address well, bytes calldata readData) view external returns (bytes memory data);
} 