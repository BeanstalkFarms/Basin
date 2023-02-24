// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, Call, MockPump} from "test/TestHelper.sol";
import {MockEmptyFunction} from "mocks/functions/MockEmptyFunction.sol";

contract WellUpdatePumpTest is TestHelper {
    function setUp() public {
        wellFunction = Call(address(new MockEmptyFunction()), "");
    }

    function test_updatePump(uint8 numPumps, bytes[8] memory pumpBytes) public {
        vm.assume(numPumps <= 8);
        for (uint i = 0; i < numPumps; i++) {
            vm.assume(pumpBytes[i].length <= 8 * 32);
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
        setupWell(2, wellFunction, pumps);

        // Perform an action on the Well to initialize pumps
        vm.prank(user);
        well.swapFrom(tokens[0], tokens[1], 1e18, 1, user);

        // During update(), MockPump sets a public storage var `lastData` equal 
        // to Call.data. 
        for (uint i = 0; i < numPumps; i++) {
            assertEq(pumps[i].data, MockPump(pumps[i].target).lastData());
        }
    }
}
