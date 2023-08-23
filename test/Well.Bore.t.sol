// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TestHelper, Well, IERC20, Call, Balances} from "test/TestHelper.sol";
import {MockPump} from "mocks/pumps/MockPump.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";
import {LibClone} from "src/libraries/LibClone.sol";

contract WellBoreTest is TestHelper {
    /// @dev Bore a 4-token Well with ConstantProduct2 & several pumps.
    function setUp() public {
        setupWell(4);

        // Well.sol doesn't use wellData, so it should always return empty bytes
        wellData = new bytes(0);
    }

    //////////// Well Definition ////////////

    function test_tokens() public {
        assertEq(well.numberOfTokens(), 4);
        assertEq(well.tokens(), tokens);
    }

    function test_wellFunction() public {
        assertEq(well.wellFunction(), wellFunction);
    }

    function test_pumps() public {
        assertEq(well.pumps(), pumps);
    }

    function test_wellData() public {
        assertEq(well.wellData(), wellData);
    }

    function test_aquifer() public {
        assertEq(well.aquifer(), address(aquifer));
    }

    function test_initialized() public {
        assertEq(well.isInitialized(), true);

        vm.expectRevert("Initializable: contract is already initialized");
        well.init("", "");
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

    function test_getReserves() public {
        assertEq(well.getReserves(), getBalances(address(well), well).tokens);
    }

    //////////// ERC20 LP Token ////////////

    function test_name() public {
        assertEq(well.name(), "TOKEN0:TOKEN1:TOKEN2:TOKEN3 Constant Product 2 Well");
    }

    function test_symbol() public {
        assertEq(well.symbol(), "TOKEN0TOKEN1TOKEN2TOKEN3CP2w");
    }

    function test_decimals() public {
        assertEq(well.decimals(), 18);
    }

    //////////// Deployment ////////////

    /// @dev Fuzz different combinations of Well configuration data and check
    /// that the Aquifer deploys everything correctly.
    function testFuzz_bore(
        uint256 numberOfPumps,
        bytes[4] memory pumpData,
        bytes memory wellFunctionBytes,
        uint256 nTokens
    ) public {
        // Constraints
        numberOfPumps = bound(numberOfPumps, 0, 4);
        for (uint256 i; i < numberOfPumps; i++) {
            vm.assume(pumpData[i].length <= 4 * 32);
        }
        vm.assume(wellFunctionBytes.length <= 4 * 32);
        nTokens = bound(nTokens, 2, tokens.length);

        // Get the first `nTokens` mock tokens
        IERC20[] memory wellTokens = getTokens(nTokens);

        // Deploy a Well Function
        wellFunction = Call(address(new ConstantProduct2()), wellFunctionBytes);

        // Etch the MockPump at each `target`
        Call[] memory pumps = new Call[](numberOfPumps);
        for (uint256 i; i < numberOfPumps; i++) {
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

        for (uint256 i; i < numberOfPumps; i++) {
            assertEq(_pumps[i], pumps[i], "pump mismatch");
        }

        // Check token addresses
        assertEq(_well.tokens(), wellTokens);

        // Check Well Function
        assertEq(_well.wellFunction(), wellFunction);
        assertEq(_well.wellFunctionAddress(), wellFunction.target);

        // Check that Aquifer recorded the deployment
        assertEq(aquifer.wellImplementation(address(_well)), wellImplementation);
        assertEq(_well.isInitialized(), true);

        vm.expectRevert("Initializable: contract is already initialized");
        _well.init("", "");
    }

    function test_notInitialized() public {
        Well _well = Well(LibClone.clone(wellImplementation));
        assertEq(_well.isInitialized(), false);
    }
}
