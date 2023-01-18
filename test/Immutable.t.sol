/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "test/TestHelper.sol";

contract ImmutableTest is TestHelper {
    function setUp() public {
        deployMockTokens(16);
        wellBuilder = new WellBuilder();
    }

    function testImmutable(
        uint8 numberOfPumps,
        bytes[6] memory pumpBytes,
        address[6] memory pumpTargets,
        bytes memory wellFunctionBytes,
        uint8 nTokens
    ) public {
        for (uint i = 0; i < 6; i++)
            vm.assume(pumpBytes[i].length < 8 * 32);
        vm.assume(numberOfPumps < 6);
        vm.assume(wellFunctionBytes.length < 32 * 32);
        vm.assume(nTokens < 4 && nTokens > 1);

        Call[] memory pumps = new Call[](numberOfPumps);
        for (uint i = 0; i < numberOfPumps; i++) {
            pumps[i].target = pumpTargets[i];
            pumps[i].data = pumpBytes[i];
        }

        address wellFunction = address(new ConstantProduct2());

        Well _well = Well(wellBuilder.buildWell(
            "",
            "",
            getTokens(nTokens), 
            Call(wellFunction, wellFunctionBytes), 
            pumps
        ));

        Call[] memory _pumps = _well.pumps();

        for (uint i = 0; i < numberOfPumps; i++) {
            assertEq(_pumps[i].target, pumps[i].target);
            assertEq(_pumps[i].data, pumps[i].data);
        }

        assertEq(_well.wellFunction().target, wellFunction);
        assertEq(_well.wellFunction().data, wellFunctionBytes);

        IERC20[] memory _tokens = _well.tokens();
        for (uint i = 0; i < nTokens; i++) {
            assertEq(address(_tokens[i]), address(tokens[i]));
        }
    }
}
