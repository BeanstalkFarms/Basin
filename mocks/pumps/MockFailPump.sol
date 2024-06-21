/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.20;

import "src/interfaces/pumps/IPump.sol";

/**
 * @title Mock Pump with a failing update function
 */
contract MockFailPump is IPump {
    function update(uint256[] calldata, bytes calldata) external pure {
        revert();
    }
}
