// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MultiFlowPump, ABDKMathQuad} from "src/pumps/MultiFlowPump.sol";
import {simCapReserve50Percent, from18, to18} from "test/pumps/PumpHelpers.sol";
import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {console, TestHelper} from "test/TestHelper.sol";

contract PumpHelpersTest is TestHelper, MultiFlowPump {
    uint256[5] testCasesInput = [1, 2, 3, 4, 5];
    uint256[5] testCasesOutput = [1, 1, 2, 2, 3];

    constructor() MultiFlowPump() {}

    function test_getSlotForAddress() public {
        address addr = address(0xa755A670Aaf1FeCeF2bea56115E65e03F7722A79);
        bytes32 bytesAddress = _getSlotForAddress(addr);

        assertEq(bytesAddress, 0xa755a670aaf1fecef2bea56115e65e03f7722a79000000000000000000000000);
    }

    function test_getDeltaTimeStamp() public {
        vm.warp(200);
        uint40 providedBlock = 100;
        uint40 expectedDelta = 100;

        uint256 delta = _getDeltaTimestamp(providedBlock);

        assertEq(delta, expectedDelta);
    }

    function test_getSlotOffset() public {
        for (uint256 i; i < testCasesInput.length; i++) {
            assertEq(_getSlotsOffset(testCasesInput[i]), testCasesOutput[i]);
        }
    }
}
