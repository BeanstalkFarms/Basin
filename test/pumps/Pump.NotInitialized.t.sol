/**
 * SPDX-License-Identifier: MIT
 *
 */
pragma solidity ^0.8.20;

import {console, TestHelper} from "test/TestHelper.sol";
import {MultiFlowPump} from "src/pumps/MultiFlowPump.sol";
import {MockReserveWell} from "mocks/wells/MockReserveWell.sol";
import {IMultiFlowPumpErrors} from "src/interfaces/pumps/IMultiFlowPumpErrors.sol";
import {from18} from "test/pumps/PumpHelpers.sol";

contract PumpNotInitialized is TestHelper {
    MultiFlowPump pump;
    MockReserveWell mWell;
    uint256[] b = new uint256[](2);

    function setUp() public {
        mWell = new MockReserveWell();
        initUser();
        pump = new MultiFlowPump(
            from18(0.5e18),
            from18(0.333333333333333333e18),
            12,
            from18(0.9e18)
        );
        uint256[] memory reserves = new uint256[](2);
        mWell.setReserves(reserves);
    }

    function test_not_initialized_last_cumulative_reserves() public {
        vm.expectRevert(IMultiFlowPumpErrors.NotInitialized.selector);
        pump.readLastCumulativeReserves(address(mWell));
    }

    function test_not_initialized_cumulative_reserves() public {
        vm.expectRevert(IMultiFlowPumpErrors.NotInitialized.selector);
        pump.readCumulativeReserves(address(mWell), new bytes(0));
    }

    function test_not_initialized_last_instantaneous_reserves() public {
        vm.expectRevert(IMultiFlowPumpErrors.NotInitialized.selector);
        pump.readLastInstantaneousReserves(address(mWell));
    }

    function test_not_initialized_instantaneous_reserves() public {
        vm.expectRevert(IMultiFlowPumpErrors.NotInitialized.selector);
        pump.readInstantaneousReserves(address(mWell), new bytes(0));
    }

    function test_not_initialized_last_capped_reserves() public {
        vm.expectRevert(IMultiFlowPumpErrors.NotInitialized.selector);
        pump.readLastCappedReserves(address(mWell));
    }

    function test_not_initialized_capped_reserves() public {
        vm.expectRevert(IMultiFlowPumpErrors.NotInitialized.selector);
        pump.readCappedReserves(address(mWell));
    }

    function test_not_initialized_twa_reserves() public {
        vm.expectRevert(IMultiFlowPumpErrors.NotInitialized.selector);
        pump.readTwaReserves(address(mWell), new bytes(0), 0, new bytes(0));
    }
}
