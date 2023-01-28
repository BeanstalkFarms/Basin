/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "src/interfaces/pumps/IPump.sol";

/**
 * @author Publius
 * @title Mock Pump
 */
contract MockPump is IPump {

    bytes public lastData;

    function attach(uint _n, bytes calldata data) external {
        lastData = "0xATTACHED";
    }

    function update(uint[] calldata, bytes calldata data) external {
        lastData = data;
    }

    function read(address well, bytes calldata readData)
        external
        view
        returns (bytes memory data)
    {
        return lastData;
    }
}
