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
     * @param pumpData pump specific data
     * @param n The number of tokens in the well
     * @dev 
     * Should be called by a Well on deployment.
     * `msg.sender` should be assumed to be the Well address.
     */
    function attach(bytes calldata pumpData, uint n) external;

    /**
     * @notice updates the pump with given data
     * @param pumpData pump specific data
     * @param balances The previous balances of the tokens in the well
     * @dev called everytime someone swaps, adds liquidity or removes liquidity from a well
     */
    function update(bytes calldata pumpData, uint[] calldata balances) external;

    /**
     * @notice reads the pump with given data
     * @param well The address of the well
     * @param n The number of tokens in the well
     * @return balances The balances of the tokens in the well
     */
    function read(address well, uint n) view external returns (uint256[] memory balances);
} 