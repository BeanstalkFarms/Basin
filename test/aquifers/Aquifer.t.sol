/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import {ConstantProduct} from "src/wellFunctions/ConstantProduct.sol";
import {Aquifer} from "src/aquifers/Aquifer.sol";
import {Auger} from "src/augers/Auger.sol";
import {Call} from "src/interfaces/IWell.sol";
import {TestHelper} from "test/TestHelper.sol";

contract AquiferTest is Aquifer, TestHelper {

    address[] wells;

    function setUp() public {
        initUser();
        deployMockTokens(10);
        aquifer = new Aquifer();
        auger = new Auger();
        Call memory wf = Call(address(new ConstantProduct()), new bytes(0));
        Call[] memory pumps = new Call[](0);
        wells.push(aquifer.boreWell(getTokens(2), wf, pumps, auger));
        wells.push(aquifer.boreWell(getTokens(2), wf, pumps, auger));
        wells.push(aquifer.boreWell(getTokens(3), wf, pumps, auger));
    }

    function testGetWellsBy2Tokens() external {
        address[] memory _wells = aquifer.getWellsBy2Tokens(tokens[0], tokens[1]);
        assertEq(_wells[0], wells[0]);
        assertEq(_wells[1], wells[1]);
        assertEq(_wells[2], wells[2]);
    }

    function testGetWellBy2Tokens() external {
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

    function testGetWellByNTokens() external {
        address _well = aquifer.getWellByNTokens(getTokens(2), 0);
        assertEq(_well, wells[0]);
        _well = aquifer.getWellByNTokens(getTokens(2), 1);
        assertEq(_well, wells[1]);
        _well = aquifer.getWellByNTokens(getTokens(3), 0);
        assertEq(_well, wells[2]);
    }

    function testGetWellsByNTokens() external {
        address[] memory _wells = aquifer.getWellsByNTokens(getTokens(2));
        assertEq(_wells[0], wells[0]);
        assertEq(_wells[1], wells[1]);
        _wells = aquifer.getWellsByNTokens(getTokens(3));
        assertEq(_wells[0], wells[2]);
    }
}
