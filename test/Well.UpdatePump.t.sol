/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";
import "mocks/functions/MockFunctionNoName.sol";

contract UpdatePumpTest is TestHelper {
    Call _wellFunction;

    function setUp() public {
        _wellFunction = Call(address(new MockFunctionNoName()), "");
    }

    function testUpdatePump(
        uint8 numberOfPumps,
        bytes[4] memory pumpBytes
    ) public {
        vm.assume(numberOfPumps < 5);
        for (uint i = 0; i < numberOfPumps; i++)
            vm.assume(pumpBytes[i].length <= 4 * 32);
        
        Call[] memory pumps = new Call[](numberOfPumps);
        for (uint i = 0; i < numberOfPumps; i++) {
            pumps[i].target = address(new MockPump());
            pumps[i].data = pumpBytes[i];
        }
        
        setupWell(2, _wellFunction, pumps);
        vm.prank(user);
        // call {swapFrom} for test coverage in updating pumps.
        well.swapFrom(tokens[0],tokens[1],1e18,1,user);
        for (uint i = 0; i < numberOfPumps; i++)
            assertEq(pumps[i].data, MockPump(pumps[i].target).lastData());
    }

}
