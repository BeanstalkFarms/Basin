/**
 * SPDX-License-Identifier: MIT
 *
 */
pragma solidity ^0.8.17;

import {console, TestHelper} from "test/TestHelper.sol";
import {GeoEmaAndCumSmaPump} from "src/pumps/GeoEmaAndCumSmaPump.sol";
import {MockReserveWell} from "mocks/wells/MockReserveWell.sol";
import {IGeoEmaAndCumSmaPumpErrors} from "src/interfaces/pumps/IGeoEmaAndCumSmaPumpErrors.sol";
import {from18} from "test/pumps/PumpHelpers.sol";

contract PumpNotInitialized is TestHelper {
    GeoEmaAndCumSmaPump pump;
    MockReserveWell mWell;
    uint256[] b = new uint256[](2);

    function setUp() public {
        mWell = new MockReserveWell();
        initUser();
        pump = new GeoEmaAndCumSmaPump(
            from18(0.5e18),
            from18(0.333333333333333333e18),
            12,
            from18(0.9e18)
        );
        uint256[] memory reserves = new uint256[](2);
        mWell.setReserves(reserves);
    }

    function test_not_initialized_last_cumulative_reserves() public {
        vm.expectRevert(IGeoEmaAndCumSmaPumpErrors.NotInitialized.selector);
        pump.readLastCumulativeReserves(address(mWell));
    }

    function test_not_initialized_cumulative_reserves() public {
        vm.expectRevert(IGeoEmaAndCumSmaPumpErrors.NotInitialized.selector);
        pump.readCumulativeReserves(address(mWell), new bytes(0));
    }

    function test_not_initialized_last_instantaneous_reserves() public {
        vm.expectRevert(IGeoEmaAndCumSmaPumpErrors.NotInitialized.selector);
        pump.readLastInstantaneousReserves(address(mWell));
    }

    function test_not_initialized_instantaneous_reserves() public {
        vm.expectRevert(IGeoEmaAndCumSmaPumpErrors.NotInitialized.selector);
        pump.readInstantaneousReserves(address(mWell), new bytes(0));
    }

    function test_not_initialized_last_reserves() public {
        vm.expectRevert(IGeoEmaAndCumSmaPumpErrors.NotInitialized.selector);
        pump.readLastReserves(address(mWell));
    }

    function test_not_initialized_twa_reserves() public {
        vm.expectRevert(IGeoEmaAndCumSmaPumpErrors.NotInitialized.selector);
        pump.readTwaReserves(address(mWell), new bytes(0), 0, new bytes(0));
    }
}
