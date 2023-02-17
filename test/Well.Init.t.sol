// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, Well, IERC20, Call, Balances} from "test/TestHelper.sol";

contract WellInitTest is TestHelper {
    event AddLiquidity(uint[] amounts);

    function setUp() public {
        setupWell(2);
    }

    //////////// Well Definition ////////////

    /// @dev tokens
    function test_tokens() public {
        check_tokens(well.tokens());
    }

    function test_getReserves() public {
        Balances memory wellBalance = getBalances(address(well), well);
        uint[] memory reserves = well.getReserves();

        assertEq(reserves[0], wellBalance.tokens[0]);
        assertEq(reserves[1], wellBalance.tokens[1]);
    }

    function check_tokens(IERC20[] memory _wellTokens) private {
        for (uint i = 0; i < tokens.length; i++) {
            assertEq(address(_wellTokens[i]), address(tokens[i]));
        }
    }

    /// @dev well function
    function test_wellFunction() public {
        check_wellFunction(well.wellFunction());
    }

    function check_wellFunction(Call memory _wellFunction) private {
        assertEq(_wellFunction.target, wellFunction.target);
        assertEq(_wellFunction.data, wellFunction.data);
    }

    /// @dev pumps
    function test_pumps() public {
        Call[] memory _wellPumps = well.pumps();
        check_pumps(_wellPumps);
    }

    function check_pumps(Call[] memory _wellPumps) private {
        assertEq(_wellPumps.length, pumps.length);
        for (uint i = 0; i < pumps.length; i++) {
            assertEq(_wellPumps[i].target, pumps[i].target);
            assertEq(_wellPumps[i].data, pumps[i].data);
        }
    }

    /// @dev aquifer
    function test_aquifer() public {
        check_aquifer(well.aquifer());
    }

    function check_aquifer(address _aquifer) public {
        assertEq(_aquifer, address(aquifer));
    }

    //// @dev Well Data
    function test_wellData() public {
        check_wellData(well.wellData());
    }

    function check_wellData(bytes memory _wellData) public {
        assertEq(_wellData, wellData);
    }

    /// @dev well
    function test_well() public {
        (
            IERC20[] memory _wellTokens,
            Call memory _wellFunction,
            Call[] memory _wellPumps,
            bytes memory _wellData,
            address _aquifer
        ) = well.well();

        check_tokens(_wellTokens);
        check_wellFunction(_wellFunction);
        check_pumps(_wellPumps);
        check_wellData(_wellData);
        check_aquifer(_aquifer);
    }

    //////////// ERC20 LP Token ////////////

    function test_name() public {
        assertEq(well.name(), "TOKEN0:TOKEN1 Constant Product Well");
    }

    function test_symbol() public {
        assertEq(well.symbol(), "TOKEN0TOKEN1CPw");
    }

    function test_decimals() public {
        assertEq(well.decimals(), 18);
    }
}
