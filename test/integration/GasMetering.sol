// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console, stdError} from "forge-std/Test.sol";

contract TestGasMetering is Test {
    //////////////////// GAS METERING ////////////////////

    /// @dev invariant test: pausing gas metering should always result
    /// in a smaller delta.
    function test_invariant_pauseGasMetering() public {
        // Expect no change once inside paused gas metering
        vm.pauseGasMetering();
        uint256 start1 = gasleft();
        {
            for (uint256 i; i < 10; i++) {
                uint256 gasnow = gasleft();
                assertEq(gasnow, start1);
            }
        }
        uint256 end1 = gasleft();
        vm.resumeGasMetering();
        assertEq(start1, end1, "Gas metering invariant: gas changed while paused");

        uint256 start2 = gasleft();
        {
            uint256 hold2 = gasleft();
            for (uint256 i; i < 10; i++) {
                uint256 gasnow = gasleft();
                assertTrue(gasnow < start2);
                assertTrue(gasnow < hold2);
                hold2 = gasnow;
            }
        }
        uint256 end2 = gasleft();

        // (start1 - end1) is zero given previous assertion
        assertTrue((start1 - end1) < (start2 - end2), "Gas metering invariant: delta");
    }

    function test_gasleft_cost() public {
        uint256 start = gasleft();
        uint256 hold = gasleft();
        uint256 end = gasleft();

        console.log("start - end", start, end, start - end);
        console.log("start - hold", start, hold, start - hold);
        console.log("hold - end", hold, end, hold - end);

        assertTrue(true);
    }

    function test_pauseGasMetering_cost() public {
        uint256 start = gasleft();
        vm.pauseGasMetering();
        uint256 hold = gasleft();
        vm.resumeGasMetering();
        uint256 end = gasleft();

        console.log("pauseGasMetering cost:", start - end);
        console.log("resumeGasMetering cost:", hold - end);

        assertTrue(true);
    }
}
