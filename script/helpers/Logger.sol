/**
 * SPDX-License-Identifier: MIT
 *
 */

pragma solidity ^0.8.13;

import {console2} from "forge-std/console2.sol";
import {console} from "forge-std/console.sol";

import {Well} from "src/Well.sol";

library logger {
    function logWell(Well well) public view {
        console.log("\nWELL:", address(well));
        console.log("Name  \t", well.name());
        console.log("Symbol\t", well.symbol());
        console.log("Auger \t", well.auger());
        console.log("tokens[0]\t", address(well.tokens()[0]));
        console.log("tokens[1]\t", address(well.tokens()[1]));
    }
}
