/**
 * SPDX-License-Identifier: MIT
 *
 */

pragma solidity ^0.8.17;

import "src/interfaces/pumps/IPump.sol";

/**
 * @title Mock Pump with a failing update function
 */
contract MockFailPump is IPump {
    function update(uint[] calldata, bytes calldata) external pure {
        revert();
    }
}
