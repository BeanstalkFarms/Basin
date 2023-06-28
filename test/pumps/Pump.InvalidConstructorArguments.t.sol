/**
 * SPDX-License-Identifier: MIT
 *
 */
pragma solidity ^0.8.17;

import {MockReserveWell} from "mocks/wells/MockReserveWell.sol";
import {IMultiFlowPumpErrors} from "src/interfaces/pumps/IMultiFlowPumpErrors.sol";
import {MultiFlowPump} from "src/pumps/MultiFlowPump.sol";
import {from18} from "test/pumps/PumpHelpers.sol";
import {console, TestHelper} from "test/TestHelper.sol";

contract PumpInvalidConstructorArguments is TestHelper {
    MultiFlowPump pump;
    MockReserveWell mWell;
    uint256[] b = new uint256[](2);

    function test_invalid_max_percent_decrease_argument_error() public {
        vm.expectRevert(
            abi.encodeWithSelector(IMultiFlowPumpErrors.InvalidMaxPercentDecreaseArgument.selector, from18(1.01e18))
        );
        pump = new MultiFlowPump(
            from18(0.5e18),
            from18(1.01e18),
            12,
            from18(0.9e18)
        );
    }

    function test_invalid_a_argument_error() public {
        vm.expectRevert(abi.encodeWithSelector(IMultiFlowPumpErrors.InvalidAArgument.selector, from18(1.01e18)));
        pump = new MultiFlowPump(
            from18(0.5e18),
            from18(1e18),
            12,
            from18(1.01e18)
        );
    }
}
