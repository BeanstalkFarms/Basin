// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console, stdError} from "forge-std/Test.sol";

contract TestGasMetering is Test {

    //////////////////// GAS METERING ////////////////////

    /// @dev invariant test: pausing gas metering should always result
    /// in a smaller delta.
    function test_invariant_pauseGasMetering() public {
        // Expect no change once inside paused gas metering
        vm.pauseGasMetering();
        uint start1 = gasleft();
        {
            for (uint i = 0; i < 10; i++) {
                uint gasnow = gasleft();
                assertEq(gasnow, start1);
            }
        }
        uint end1 = gasleft();
        vm.resumeGasMetering();
        assertEq(start1, end1, "Gas metering invariant: gas changed while paused");

        uint start2 = gasleft();
        {
            uint hold2 = gasleft();
            for (uint i = 0; i < 10; i++) {
                uint gasnow = gasleft();
                assertTrue(gasnow < start2);
                assertTrue(gasnow < hold2);
                hold2 = gasnow;
            }
        }
        uint end2 = gasleft();

        // (start1 - end1) is zero given previous assertion
        assertTrue((start1 - end1) < (start2 - end2), "Gas metering invariant: delta");
    }

    function test_gasleft_cost() public {
        uint start = gasleft();  
        uint hold = gasleft(); 
        uint end = gasleft();

        console.log("start - end", start, end, start-end);
        console.log("start - hold", start, hold, start-hold);
        console.log("hold - end", hold, end, hold-end);

        assertTrue(true);
    }

    function test_pauseGasMetering_cost() public {
        uint start = gasleft();
        vm.pauseGasMetering();
        uint hold = gasleft();
        vm.resumeGasMetering();
        uint end = gasleft();
        
        console.log("pauseGasMetering cost:", start - end);
        console.log("resumeGasMetering cost:", hold - end);

        assertTrue(true);
    }
}