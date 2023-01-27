// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Well} from "src/Well.sol";
import {TestHelper} from "test/TestHelper.sol";

contract AugerTest is TestHelper {
    Well well2;
    Well well3;

    function setUp() public {
        setupWell(2); // initializes well components
        well2 = new Well("Well", "WELL", tokens, wellFunction, pumps);
        well3 = Well(auger.bore("Well", "WELL", tokens, wellFunction, pumps));
    }

    function test_wellAuger() public {
        assertEq(well2.auger(), address(this)); // Well deployed by AugerTest
        assertEq(well3.auger(), address(auger)); // Well deployed by auger
    }
}
