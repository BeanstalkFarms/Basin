/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.20;

import {IPump} from "src/interfaces/pumps/IPump.sol";

/**
 * @notice Mock Well that fails on various init calls.
 */
contract MockInitFailWell {
    function initNoMessage() external pure {
        revert();
    }

    function initMessage() external pure {
        revert("Well: fail message");
    }
}
