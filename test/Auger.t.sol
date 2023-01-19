/**
 * SPDX-License-Identifier: MIT
 *
 */
pragma solidity ^0.8.17;

import {TestHelper} from "test/TestHelper.sol";
import {Well} from "src/Well.sol";

contract AugerTest is TestHelper {
    Well well2;
    Well well3;

    function setUp() public {
        setupWell(2); // initializes well components
        well2 = new Well("Well", "WELL", tokens, wellFunction, pumps);
        well3 = Well(auger.bore("Well", "WELL", tokens, wellFunction, pumps));
    }

    function test_wellAuger() public {
        assertEq(well2.auger(), address(this)); // deployed by AugerTest
        assertEq(well3.auger(), address(auger)); // deployed by auger
    }

    /// @dev Deploy a Well manually and via the auger; bytecode should match
    // function test_bytecodeMatch() public {
    //     assertEq(address(well2).code, address(well3).code);
    // }
}
