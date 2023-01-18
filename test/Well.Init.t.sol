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
    
    /// @dev tokens
    function testTokens() public {
        _testTokens(well.tokens());
    }
    function _testTokens(IERC20[] memory _wellTokens) private {
        for (uint i = 0; i < tokens.length; i++) {
            console.log(address(_wellTokens[i]));
            assertEq(address(_wellTokens[i]), address(tokens[i]));
        }
    }
 
    /// @dev well function
    function testWellFunction() public {
        _testWellFunction(well.wellFunction());
    }
    function _testWellFunction(Call memory _wellFunction) private {
        assertEq(_wellFunction.target, wellFunction.target);
        assertEq(_wellFunction.data, wellFunction.data);
    }

    /// @dev pumps
    function testPumps() public {
        Call memory _wellPump = well.pump();
        _testPumps(_wellPump);
    }
    function _testPumps(Call memory _wellPump) private {
        assertEq(_wellPump.target, pump.target);
        assertEq(_wellPump.data, pump.data);
    }

    /// @dev well
    function testWell() public {
        (
            IERC20[] memory _wellTokens,
            Call memory _wellFunction,
            Call memory _wellPump
        ) = well.well();
        
        _testTokens(_wellTokens);
        _testWellFunction(_wellFunction);
        _testPumps(_wellPump);
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

    function testTotalSupply() public {
        // initializing a 2-token well adds 1000 * 1e18 of each token as liquidity
        assertEq(well.totalSupply(), 2000 * 1e27);
    }
}
