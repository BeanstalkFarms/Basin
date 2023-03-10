// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {MockToken, TestHelper, Balances} from "test/TestHelper.sol";

contract WellSyncTest is TestHelper {
    event Sync(uint[] reserves);

    function setUp() public {
        setupWell(2);

        // Let `user` burn
        vm.startPrank(address(well));
        MockToken(address(tokens[0])).approve(address(user), type(uint).max);
        MockToken(address(tokens[1])).approve(address(user), type(uint).max);
        vm.stopPrank();
    }

    function test_initialized() public {
        Balances memory wellBalance = getBalances(address(well), well);
        assertEq(wellBalance.tokens[0], 1000 * 1e18);
        assertEq(wellBalance.tokens[1], 1000 * 1e18);
    }

    function test_syncDown() public prank(user) {
        MockToken(address(tokens[0])).burnFrom(address(well), 1e18);
        MockToken(address(tokens[1])).burnFrom(address(well), 1e18);

        uint[] memory expectedReserves = new uint[](2);
        expectedReserves[0] = 999e18;
        expectedReserves[1] = 999e18;

        vm.expectEmit(true, true, true, true);
        emit Sync(expectedReserves);

        well.sync();

        uint[] memory reserves = well.getReserves();
        assertEq(reserves[0], expectedReserves[0], "Reserve 0 should be 1e18");
        assertEq(reserves[1], expectedReserves[1], "Reserve 1 should be 1e18");
    }

    function test_syncUp() public prank(user) {
        MockToken(address(tokens[0])).mint(address(well), 1e18);
        MockToken(address(tokens[1])).mint(address(well), 1e18);

        uint[] memory expectedReserves = new uint[](2);
        expectedReserves[0] = 1001e18;
        expectedReserves[1] = 1001e18;

        vm.expectEmit(true, true, true, true);
        emit Sync(expectedReserves);

        well.sync();

        uint[] memory reserves = well.getReserves();
        assertEq(reserves[0], expectedReserves[0], "Reserve 0 should be Balance 0");
        assertEq(reserves[1], expectedReserves[1], "Reserve 1 should be Balance 1");
    }

    function testFuzz_sync(uint128[2] calldata mintAmount, uint128[2] calldata burnAmount) public prank(user) {
        uint temp = bound(mintAmount[0], 0, type(uint128).max - tokens[0].balanceOf(address(well)) - 100);
        MockToken(address(tokens[0])).mint(address(well), temp);
        temp = bound(mintAmount[1], 0, type(uint128).max - tokens[1].balanceOf(address(well)) - 100);
        MockToken(address(tokens[1])).mint(address(well), temp);
        temp = bound(burnAmount[0], 0, tokens[0].balanceOf(address(well)));
        MockToken(address(tokens[0])).burnFrom(address(well), temp);
        temp = bound(burnAmount[1], 0, tokens[1].balanceOf(address(well)));
        MockToken(address(tokens[1])).burnFrom(address(well), temp);

        uint[] memory balances = new uint[](2);
        balances[0] = tokens[0].balanceOf(address(well));
        balances[1] = tokens[1].balanceOf(address(well));

        vm.expectEmit(true, true, true, true);
        emit Sync(balances);

        well.sync();

        uint[] memory reserves = well.getReserves();
        assertEq(reserves[0], balances[0], "Reserve 0 should be Balance 0");
        assertEq(reserves[1], balances[1], "Reserve 1 should be Balance 1");
    }
}
