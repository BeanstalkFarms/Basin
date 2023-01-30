// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "test/TestHelper.sol";
import "src/pumps/GeoEmaAndCumSmaPump.sol";

import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";

contract PumpUpdateTest is TestHelper {
    GeoEmaAndCumSmaPump pump;
    uint[] b = new uint[](2);

    function setUp() public {
        initUser();
        pump = new GeoEmaAndCumSmaPump(0.5e18, 12, 0.9e18);
        b[0] = 1e6;
        b[1] = 2e6;
        vm.prank(user);
        pump.update(b, new bytes(0));
    }

    function testFirstSet() public prank(user) {
        uint[] memory lastReserves = pump.readLastReserves(user);
        assertEq(lastReserves[0], 1e6);
        assertEq(lastReserves[1], 2e6);
        console.log("a");
        uint[] memory lastEmaReserves = pump.readInstantaneousReserves(user);
        console.log("b");
        assertEq(lastEmaReserves[0], 1e6);
        assertEq(lastEmaReserves[1], 2e6);
        console.log("c");
        uint[] memory lastCumulativeReserves = pump.readLastCumulativeReserves(user);
        console.log("d");
        assertEq(lastCumulativeReserves[0], 0);
        assertEq(lastCumulativeReserves[1], 0);
    }

    function testUpdate0Seconds() public prank(user) {
        b[0] = 2e6;
        b[1] = 1e6;
        pump.update(b, new bytes(0));
        uint[] memory lastReserves = pump.readLastReserves(user);
        assertEq(lastReserves[0], 1e6);
        assertEq(lastReserves[1], 2e6);
        uint[] memory lastEmaReserves = pump.readInstantaneousReserves(user);
        assertEq(lastEmaReserves[0], 1e6);
        assertEq(lastEmaReserves[1], 2e6);
        uint[] memory lastCumulativeReserves = pump.readLastCumulativeReserves(user);
        assertEq(lastCumulativeReserves[0], 0);
        assertEq(lastCumulativeReserves[1], 0);
    }

    function testUpdate12Seconds() public prank(user) {
        increaseTime(12);
        b[0] = 2e6;
        b[1] = 1e6;
        pump.update(b, new bytes(0));
        uint[] memory lastReserves = pump.readLastReserves(user);
        assertEq(lastReserves[0], 1.5e6);
        assertEq(lastReserves[1], 1e6);
        uint[] memory lastEmaReserves = pump.readInstantaneousReserves(user);
        assertEq(lastEmaReserves[0], 1_337_698);
        assertEq(lastEmaReserves[1], 1_216_242);
        uint[] memory lastCumulativeReserves = pump.readLastCumulativeReserves(user);
        assertEq(lastCumulativeReserves[0], 20_516_531_070_045_330_241 * 12);
        assertEq(lastCumulativeReserves[1], 19_931_568_569_324_174_075 * 12);
    }
}
