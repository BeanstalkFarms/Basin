// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TestHelper, Balances, Call} from "test/TestHelper.sol";
import {MockFailPump} from "mocks/pumps/MockFailPump.sol";

contract WellSucceedOnPumpFailure is TestHelper {
    MockFailPump _pump;

    function setUp() public {
        _pump = new MockFailPump();
    }

    // Check that the pump function fails as expected
    function test_fail() public {
        vm.expectRevert();
        uint256[] memory amounts = new uint256[](2);
        _pump.update(amounts, new bytes(0));
    }

    // Check that the Well doesn't fail if one of one fail
    function test_addLiquidty_onePump() public {
        Call[] memory pumps = new Call[](1);
        pumps[0].target = address(_pump);
        setupWell(2, pumps);
        // Check that the add liquidity call succeeded during well setup.
        assertGt(well.totalSupply(), 0);
    }

    // Check that the Well doesn't fail if m of n pumps fail
    function test_addLiquidty_twoPumps() public {
        Call[] memory pumps = new Call[](2);
        pumps[0].target = address(_pump);
        pumps[1].target = address(new MockFailPump());
        setupWell(2, pumps);
        // Check that the add liquidity call succeeded during well setup.
        assertGt(well.totalSupply(), 0);
    }
}
