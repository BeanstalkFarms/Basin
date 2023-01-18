/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "forge-std/console2.sol";
import "test/TestHelper.sol";
import "utils/RandomBytes.sol";

contract ImmutableTest is TestHelper, RandomBytes {
    function setUp() public {
        deployMockTokens(16);
        wellBuilder = new WellBuilder();
    }

    function testImmutable(
        uint16 nPump,
        uint16 nWellFunction,
        uint8 nTokens
    ) public {
        // The below constraints assume default configuration for immutable storage.
        // Developers may choose to change immutable storage layout to meet the needs
        // of a particular well. In this instance, the below constraints should be
        // appropriately adjusted.
        vm.assume(nTokens >= 2);
        vm.assume(nTokens <= 4); // ImmutableTokens.MAX_TOKENS
        vm.assume(nWellFunction >= 0);
        vm.assume(nWellFunction <= 4*32); // ImmutableWellFunction.MAX_SIZE
        vm.assume(nPump >= 0);
        vm.assume(nPump <= 4*32); // ImmutablePump.MAX_SIZE

        bytes memory pumpBytes = getRandomBytes(nPump);
        bytes memory wellFunctionBytes = getRandomBytes(nWellFunction);
        address wellFunction = address(new ConstantProduct2());

        Well _well = Well(wellBuilder.buildWell(
            "",
            "",
            getTokens(nTokens), 
            Call(wellFunction, wellFunctionBytes), 
            Call(address(0), pumpBytes)
        ));

        assertEq(_well.pump().target, address(0));
        assertEq(_well.pump().data, pumpBytes);

        assertEq(_well.wellFunction().target, wellFunction);
        assertEq(_well.wellFunction().data, wellFunctionBytes);

        IERC20[] memory _tokens = _well.tokens();
        for (uint i = 0; i < nTokens; i++) {
            assertEq(address(_tokens[i]), address(tokens[i]));
        }
    }
}
