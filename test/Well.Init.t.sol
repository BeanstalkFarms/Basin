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

    //////////// Well Definition ////////////
    
    function testTokens() public {
        _testTokens(well.tokens());
    }
    function _testTokens(IERC20[] memory _wellTokens) private {
        for (uint i = 0; i < tokens.length; i++) {
            assertEq(address(_wellTokens[i]), address(tokens[i]));
        }
    }
 
    function testWellFunction() public {
        _testWellFunction(well.wellFunction());
    }
    function _testWellFunction(Call memory _wellFunction) private {
        assertEq(_wellFunction.target, wellFunction.target);
        assertEq(_wellFunction.data, wellFunction.data);
    }

    function testPumps() public {
        Call[] memory _wellPumps = well.pumps();
        _testPumps(_wellPumps);
    }
    function _testPumps(Call[] memory _wellPumps) private {
        assertEq(_wellPumps.length, pumps.length);
        for (uint i = 0; i < pumps.length; i++) {
            assertEq(_wellPumps[i].target, pumps[i].target);
            assertEq(_wellPumps[i].data, pumps[i].data);
        }
    }

    function testWell() public {
        (
            IERC20[] memory _wellTokens,
            Call memory _wellFunction,
            Call[] memory _wellPumps
        ) = well.well();
        
        _testTokens(_wellTokens);
        _testWellFunction(_wellFunction);
        _testPumps(_wellPumps);
    }

    //////////// ERC20 Token ////////////

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
