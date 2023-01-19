/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";

contract WellInitTest is TestHelper {

    function setUp() public {
        setupWell(2);
    }

    function testSkim(uint[2] calldata amounts) prank(user) public {
        vm.assume(amounts[0] <= 1000e18);
        vm.assume(amounts[1] <= 1000e18);

        tokens[0].transfer(address(well), amounts[0]);
        tokens[1].transfer(address(well), amounts[0]);

        well.skim(user);

        assertEq(tokens[0].balanceOf(address(well)), 1000e18);
        assertEq(tokens[1].balanceOf(address(well)), 1000e18);
        assertEq(tokens[0].balanceOf(user), 1000e18);
        assertEq(tokens[1].balanceOf(user), 1000e18);
    }
}
