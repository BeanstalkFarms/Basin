/**
 * SPDX-License-Identifier: MIT
 *
 */
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
    }

    function testFuzz_update(
        uint128[8] memory initReserves,
        uint128[8] memory reserves,
        uint8 n,
        uint40 timeIncrease,
        uint40 timeIncrease2
    ) public prank(user) {
        vm.assume(n < 9);
        vm.assume(n > 0);
        vm.assume(block.timestamp + timeIncrease + timeIncrease2 <= type(uint40).max);

        uint[] memory b = new uint[](n);
        for (uint i = 0; i < n; i++) {
            vm.assume(initReserves[i] > 0);
            b[i] = initReserves[i];
        }
        console.log(1);

        pump.update(b, new bytes(0));
        console.log(2);

        uint[] memory startCumulativeReserves = pump.readCumulativeReserves(user);
        uint startTimestamp = block.timestamp;
        console.log(3);

        // Update Pump
        for (uint i = 0; i < n; i++) {
            vm.assume(reserves[i] > 0);
            b[i] = reserves[i];
        }
        console.log(4);
        increaseTime(timeIncrease);
        pump.update(b, new bytes(0));
        console.log(5);

        // TODO
        // if (timeIncrease > 0) {
        //     (uint[] memory twaReserves,) = pump.readTwaReserves(
        //         user,
        //         startCumulativeReserves,
        //         startTimestamp
        //     );
        //     assertEq(twaReserves[0], reserves[0]);
        //     assertEq(twaReserves[1], reserves[1]);
        // }
    }
}
