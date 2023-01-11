/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";

contract WellInitTest is TestHelper {

    Well noNameWell;

    event AddLiquidity(uint[] amounts);

    function setUp() public {
        setupWell(2);
    }

    function testTokens() public {
        IERC20[] memory wellTokens = well.tokens();
        for (uint i = 0; i < tokens.length; i++) {
            console.log(address(wellTokens[i]));
            assertEq(address(wellTokens[i]), address(tokens[i]));
        }
    }

    function testPumps() public {
        Call memory wellPump = well.pump();
        assertEq(wellPump.target, pump.target);
        assertEq(wellPump.data, pump.data);
    }

    function testName() public {
        assertEq(well.name(), "TOKEN0:TOKEN1 Constant Product Well");
    }

    function testSymbol() public {
        assertEq(well.symbol(), "TOKEN0TOKEN1CPw");
    }

    function testDecimals() public {
        assertEq(well.decimals(), 18);
    }
}
