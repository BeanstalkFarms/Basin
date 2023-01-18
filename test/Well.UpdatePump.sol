/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";

contract UpdatePumpTest is TestHelper {

    function setUp() public {
        pumps.push(Call(address(new MockPump()), "abcd"));
        setupWell(2);
    }

    function testUpdatePump() public {
        bytes memory data = MockPump(pumps[0].target).lastData();
        assertEq(data, "abcd");
    }
}
