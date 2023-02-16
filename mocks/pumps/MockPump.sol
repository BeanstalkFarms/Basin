/**
 * SPDX-License-Identifier: MIT
 *
 */

pragma solidity ^0.8.17;

import "src/interfaces/pumps/IPump.sol";

/**
 * @author Publius
 * @title Mock Pump
 */
contract MockPump is IPump {
    bytes public lastData;

    function attach(uint, bytes calldata) external {
        lastData = "0xATTACHED";
    }

    function update(uint[] calldata, bytes calldata data) external {
        lastData = data;
    }

    function read(address, bytes calldata)
        external
        view
        returns (bytes memory data)
    {
        return lastData;
    }
}
