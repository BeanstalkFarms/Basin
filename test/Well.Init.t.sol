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
        // TODO: add name/symbol tests
    }

    function testWellInfo() public {
        WellInfo memory wi = well.wellInfo();
        for (uint i = 0; i < tokens.length; i++)
            assertEq(address(wi.tokens[i]), address(w.tokens[i]));
        for (uint i = 0; i < w.pumps.length; i++) {
            assertEq(wi.pumps[i].target, w.pumps[i].target);
            assertEq(wi.pumps[i].data, w.pumps[i].data);
        }
        assertEq(wi.wellFunction.target, w.wellFunction.target);
        assertEq(wi.wellFunction.data, w.wellFunction.data);
    }

    function testWellHash() public {
        bytes32 wellHash = well.wellHash();
        assertEq(wellHash, wellBuilder.getWellHash(w));
    }

    function testTokens() public {
        IERC20[] memory wellTokens = well.tokens();
        for (uint i = 0; i < tokens.length; i++)
            assertEq(address(wellTokens[i]), address(tokens[i]));
    }

    function testPumps() public {
        Call[] memory wellPumps = well.pumps();
        for (uint i = 0; i < w.pumps.length; i++) {
            assertEq(wellPumps[i].target, w.pumps[i].target);
            assertEq(wellPumps[i].data, w.pumps[i].data);
        }
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
