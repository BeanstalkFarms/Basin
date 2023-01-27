// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/console2.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";
import {Well, Call, TestHelper, IERC20, MockPump} from "test/TestHelper.sol";
import {RandomBytes} from "test/helpers/RandomBytes.sol";

contract ImmutableTest is TestHelper {
    function setUp() public {
        deployMockTokens(16);
    }

    /// @dev immutable storage should work when any number of its slots are filled
    function testImmutable(
        uint8 numberOfPumps,
        bytes[4] memory pumpBytes,
        address[4] memory pumpTargets,
        bytes memory wellFunctionBytes,
        uint8 nTokens
    ) public {
        vm.assume(numberOfPumps < 5);
        for (uint i = 0; i < numberOfPumps; i++) {
            vm.assume(pumpBytes[i].length <= 4 * 32);
        }
        for (uint i = 0; i < pumpTargets.length; i++) {
            vm.assume(pumpTargets[i] != address(0));
        }
        vm.assume(wellFunctionBytes.length <= 4 * 32);
        vm.assume(nTokens < 4 && nTokens > 1);

        // Deploy a MockPump
        MockPump mockPump = new MockPump();
        bytes memory code = address(mockPump).code;

        // Etch mock pump at each target and build pumps array
        Call[] memory pumps = new Call[](numberOfPumps);
        for (uint i = 0; i < numberOfPumps; i++) {
            pumps[i].target = pumpTargets[i];
            pumps[i].data = pumpBytes[i];
            vm.etch(pumpTargets[i], code);
        }

        address wellFunction = address(new ConstantProduct2());
        Well _well = new Well(
            "",
            "",
            getTokens(nTokens), 
            Call(wellFunction, wellFunctionBytes), 
            pumps
        );

        // Check pumps
        Call[] memory _pumps = _well.pumps();
        for (uint i = 0; i < numberOfPumps; i++) {
            assertEq(_pumps[i].target, pumps[i].target);
            assertEq(_pumps[i].data, pumps[i].data);
            assertEq(address(pumps[i].target).code, code, "Pump code should be etched");
            assertEq(MockPump(pumps[i].target).lastData(), "0xATTACHED", "Pump should be attached");
        }

        // Check well function
        assertEq(_well.wellFunction().target, wellFunction);
        assertEq(_well.wellFunction().data, wellFunctionBytes);

        // Check token addresses;
        IERC20[] memory _tokens = _well.tokens();
        for (uint i = 0; i < nTokens; i++) {
            assertEq(address(_tokens[i]), address(tokens[i]));
        }
    }
}
