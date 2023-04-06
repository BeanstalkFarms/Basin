/**
 * SPDX-License-Identifier: MIT
 *
 */
pragma solidity ^0.8.17;

import {MockReserveWell} from "mocks/wells/MockReserveWell.sol";
import {IPumpErrors} from "src/interfaces/pumps/IPumpErrors.sol";
import {GeoEmaAndCumSmaPump} from "src/pumps/GeoEmaAndCumSmaPump.sol";
import {from18} from "test/pumps/PumpHelpers.sol";
import {console, TestHelper} from "test/TestHelper.sol";

contract PumpInvalidConstructor is TestHelper {
    GeoEmaAndCumSmaPump pump;
    MockReserveWell mWell;
    uint[] b = new uint[](2);

    function test_invalid_constructor_argument() public {
        vm.expectRevert(abi.encodeWithSelector(IPumpErrors.InvalidConstructorArgument.selector, from18(1e18)));
        pump = new GeoEmaAndCumSmaPump(
            from18(0.5e18),
            from18(1e18),
            12,
            from18(0.9e18)
        );
    }
}