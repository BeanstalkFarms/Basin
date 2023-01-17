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
        nPump = nPump / 64;
        nWellFunction = nWellFunction / 64;
        nTokens = nTokens / 16;
        if (nTokens < 2) nTokens = 2;

        bytes memory pumpBytes = getRandomBytes(nPump);
        bytes memory wellFunctionBytes = getRandomBytes(nWellFunction);
        address wellFunction = address(new ConstantProduct2());

        Well _well = Well(wellBuilder.buildWell(
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
