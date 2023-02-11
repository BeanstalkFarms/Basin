// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {TestHelper, IERC20} from "test/TestHelper.sol";

import {IWell, Call} from "src/interfaces/IWell.sol";

import {ConstantProduct} from "src/functions/ConstantProduct.sol";
import {Auger} from "src/Auger.sol";
import {Aquifer} from "src/Aquifer.sol";

contract AquiferTest is TestHelper {
    address[] wells;

    event BoreWell(address well, IERC20[] tokens, Call wellFunction, Call[] pumps, address auger);

    function setUp() public {
        initUser();
        deployMockTokens(10);

        // Create Auger & Aquifer
        auger = new Auger();
        aquifer = new Aquifer();

        // Prep Wells
        wellFunction = Call(address(new ConstantProduct()), new bytes(0));

        wells.push(aquifer.boreWell(getTokens(2), wellFunction, pumps, auger));
        wells.push(aquifer.boreWell(getTokens(2), wellFunction, pumps, auger));
        wells.push(aquifer.boreWell(getTokens(3), wellFunction, pumps, auger));
    }

    //////////// DEPLOYMENT ////////////

    /// @dev events cannot be checked as the address is not known
    // prior to deployment
    // FIXME: should we add a salt when deploying a well so that this can be tested?
    function test_boreEvent() external {
        IERC20[] memory _tokens = getTokens(2);

        vm.expectEmit(true, true, true, false, address(aquifer));
        emit BoreWell(
            address(0), // unknown
            _tokens,
            wellFunction,
            pumps,
            address(auger)
            );

        aquifer.boreWell(_tokens, wellFunction, pumps, auger);
    }

    //////////// LOOKUPS ////////////

    function test_getWellsBy2Tokens() external {
        address[] memory _wells = aquifer.getWellsBy2Tokens(tokens[0], tokens[1]);
        assertEq(_wells[0], wells[0]);
        assertEq(_wells[1], wells[1]);
        assertEq(_wells[2], wells[2]);
    }

    function test_getWellBy2Tokens() external {
        address _well = aquifer.getWellBy2Tokens(tokens[0], tokens[1], 0);
        assertEq(_well, wells[0]);
        _well = aquifer.getWellBy2Tokens(tokens[0], tokens[1], 1);
        assertEq(_well, wells[1]);
        _well = aquifer.getWellBy2Tokens(tokens[0], tokens[1], 2);
        assertEq(_well, wells[2]);
        _well = aquifer.getWellBy2Tokens(tokens[1], tokens[2], 0);
        assertEq(_well, wells[2]);
        _well = aquifer.getWellBy2Tokens(tokens[0], tokens[2], 0);
        assertEq(_well, wells[2]);
    }

    function test_getWellByNTokens() external {
        address _well = aquifer.getWellByNTokens(getTokens(2), 0);
        assertEq(_well, wells[0]);
        _well = aquifer.getWellByNTokens(getTokens(2), 1);
        assertEq(_well, wells[1]);
        _well = aquifer.getWellByNTokens(getTokens(3), 0);
        assertEq(_well, wells[2]);
    }

    function test_getWellsByNTokens() external {
        address[] memory _wells = aquifer.getWellsByNTokens(getTokens(2));
        assertEq(_wells[0], wells[0]);
        assertEq(_wells[1], wells[1]);
        _wells = aquifer.getWellsByNTokens(getTokens(3));
        assertEq(_wells[0], wells[2]);
    }

    function test_getWellByIndex() external {
        address _well = aquifer.getWellByIndex(0);
        assertEq(_well, wells[0]);
    }
}
