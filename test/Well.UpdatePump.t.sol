/**
 * SPDX-License-Identifier: MIT
 *
 */
pragma solidity ^0.8.17;

import {TestHelper, Call, MockPump} from "test/TestHelper.sol";
import {MockFunctionNoName} from "mocks/functions/MockFunctionNoName.sol";

contract WellUpdatePumpTest is TestHelper {
    Call _wellFunction;

    function setUp() public {
        _wellFunction = Call(address(new MockFunctionNoName()), "");
    }

    function test_updatePump(uint8 numPumps, bytes[4] memory pumpBytes) public {
        // The base Well supports 4 pumps with up to
        // 4 * 32 bytes of extra data each
        vm.assume(numPumps <= 4);
        for (uint i = 0; i < numPumps; i++) {
            vm.assume(pumpBytes[i].length <= 4 * 32);
        }

        // Create `numPumps` Call structs
        Call[] memory pumps = new Call[](numPumps);
        for (uint i = 0; i < numPumps; i++) {
            pumps[i].target = address(new MockPump());
            pumps[i].data = pumpBytes[i];
        }

        // Setup a Well with multiple pumps and test each
        // FIXME: this works because liquidity is deployed which switches
        // lastData from "0xATTACHED" to the `data` param which is passed during
        // the `update()` call. If liquidity is not added, this will fail.
        setupWell(2, _wellFunction, pumps);
        vm.prank(user);
        // call {swapFrom} for test coverage in updating pumps.
        well.swapFrom(tokens[0], tokens[1], 1e18, 1, user);
        for (uint i = 0; i < numPumps; i++) {
            assertEq(pumps[i].data, MockPump(pumps[i].target).lastData());
        }
    }
}
