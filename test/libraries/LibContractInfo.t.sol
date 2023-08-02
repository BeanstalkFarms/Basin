// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, console} from "test/TestHelper.sol";
import {LibContractInfo} from "src/libraries/LibContractInfo.sol";

contract Hi {}

contract LibContractInfoTest is TestHelper {
    using LibContractInfo for address;

    Hi hi;

    function setUp() public {
        hi = new Hi();
        setupWell(2); // setting up a well just to get some mock tokens
    }

    function test_getSymbol() public {
        assertEq(address(tokens[0]).getSymbol(), "TOKEN0");
        assertEq(address(hi).getSymbol(), "5615");
    }

    function test_getName() public {
        assertEq(address(tokens[0]).getName(), "Token 0");
        assertEq(address(hi).getName(), "5615deb7");
    }
}
