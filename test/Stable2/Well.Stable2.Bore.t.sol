// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, Well, IERC20, Call, Balances} from "test/TestHelper.sol";
import {MockPump} from "mocks/pumps/MockPump.sol";
import {Stable2} from "src/functions/Stable2.sol";
import {Stable2LUT1} from "src/functions/StableLUT/Stable2LUT1.sol";

contract WellStable2BoreTest is TestHelper {
    /// @dev Bore a 2-token Well with Stable2 & several pumps.
    function setUp() public {
        setupStable2Well();
        // Well.sol doesn't use wellData, so it should always return empty bytes
        wellData = new bytes(0);
    }

    //////////// Well Definition ////////////

    function test_tokens() public {
        assertEq(well.tokens(), tokens);
    }

    function test_wellFunction() public {
        assertEq(well.wellFunction(), wellFunction);
    }

    function test_pumps() public {
        assertEq(well.pumps(), pumps);
    }

    function test_wellData() public view {
        assertEq(well.wellData(), wellData);
    }

    function test_aquifer() public view {
        assertEq(well.aquifer(), address(aquifer));
    }

    function test_well() public {
        (
            IERC20[] memory _wellTokens,
            Call memory _wellFunction,
            Call[] memory _wellPumps,
            bytes memory _wellData,
            address _aquifer
        ) = well.well();

        assertEq(_wellTokens, tokens);
        assertEq(_wellFunction, wellFunction);
        assertEq(_wellPumps, pumps);
        assertEq(_wellData, wellData);
        assertEq(_aquifer, address(aquifer));
    }

    function test_getReserves() public view {
        assertEq(well.getReserves(), getBalances(address(well), well).tokens);
    }

    //////////// ERC20 LP Token ////////////

    function test_name() public view {
        assertEq(well.name(), "TOKEN0:TOKEN1 Stable2 Well");
    }

    function test_symbol() public view {
        assertEq(well.symbol(), "TOKEN0TOKEN1S2w");
    }

    function test_decimals() public view {
        assertEq(well.decimals(), 18);
    }

    //////////// Deployment ////////////

    /// @dev Fuzz different combinations of Well configuration data and check
    /// that the Aquifer deploys everything correctly.
    function testFuzz_bore(uint256 numberOfPumps, bytes[4] memory pumpData, uint256 nTokens, uint256 a) public {
        // Constraints
        numberOfPumps = bound(numberOfPumps, 0, 4);
        for (uint256 i = 0; i < numberOfPumps; i++) {
            vm.assume(pumpData[i].length <= 4 * 32);
        }
        nTokens = bound(nTokens, 2, tokens.length);

        vm.assume(a > 0);
        // Get the first `nTokens` mock tokens
        IERC20[] memory wellTokens = getTokens(nTokens);
        bytes memory wellFunctionBytes = abi.encode(a, address(wellTokens[0]), address(wellTokens[1]));

        // Deploy a Well Function
        address lut = address(new Stable2LUT1());
        wellFunction = Call(address(new Stable2(lut)), wellFunctionBytes);

        // Etch the MockPump at each `target`
        Call[] memory pumps = new Call[](numberOfPumps);
        for (uint256 i = 0; i < numberOfPumps; i++) {
            pumps[i].target = address(new MockPump());
            pumps[i].data = pumpData[i];
        }

        // Deploy the Well
        Well _well =
            encodeAndBoreWell(address(aquifer), wellImplementation, wellTokens, wellFunction, pumps, bytes32(0));

        // Check Pumps
        assertEq(_well.numberOfPumps(), numberOfPumps, "number of pumps mismatch");
        Call[] memory _pumps = _well.pumps();

        if (numberOfPumps > 0) {
            assertEq(_well.firstPump(), pumps[0], "pump mismatch");
        }

        for (uint256 i = 0; i < numberOfPumps; i++) {
            assertEq(_pumps[i], pumps[i], "pump mismatch");
        }

        // Check token addresses
        assertEq(_well.tokens(), wellTokens);

        // Check Well Function
        assertEq(_well.wellFunction(), wellFunction);
        assertEq(_well.wellFunctionAddress(), wellFunction.target);

        // Check that Aquifer recorded the deployment
        assertEq(aquifer.wellImplementation(address(_well)), wellImplementation);
    }
}
