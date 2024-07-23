/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.20;

import "src/interfaces/pumps/IPump.sol";

/**
 * @author Brendan
 * @title Mock Pump
 */
contract MockPump is IPump {
    bytes public lastData;

    function update(uint256[] calldata, bytes calldata data) external {
        lastData = data;
    }

    function read(address, bytes calldata) external view returns (bytes memory data) {
        return lastData;
    }
}
