/**
 * SPDX-License-Identifier: MIT
 *
 */
pragma solidity ^0.8.17;

import "test/TestHelper.sol";
import "src/pumps/GeoEmaAndCumSmaPump.sol";

import {from18, to18} from "test/pumps/PumpHelpers.sol";
import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";

contract PumpFuzzTest is TestHelper {
    GeoEmaAndCumSmaPump pump;
    uint[] b = new uint[](2);

    function setUp() public {
        initUser();
        pump = new GeoEmaAndCumSmaPump(from18(0.5e18), from18(0.333333333333333333e18), 12, from18(0.9e18));
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
            // TODO: relax assumption
            vm.assume(initReserves[i] > 100);
            b[i] = initReserves[i];
        }

        pump.update(b, new bytes(0));

        bytes memory startCumulativeReserves = pump.readCumulativeReserves(user);
        uint startTimestamp = block.timestamp;

        bytes16[] memory reserveBytes = abi.decode(startCumulativeReserves, (bytes16[]));

        // Update Pump
        for (uint i = 0; i < n; i++) {
            // TODO: relax assumption
            vm.assume(initReserves[i] > 1e12);
            vm.assume(reserves[i] > 1e12);
            b[i] = reserves[i];
        }

        increaseTime(timeIncrease);
        pump.update(b, new bytes(0));

        bytes memory endCumulativeReserves = pump.readCumulativeReserves(user);
        reserveBytes = abi.decode(endCumulativeReserves, (bytes16[]));

        // TODO: remove time increase
        if (timeIncrease > 0) {
            (uint[] memory twaReserves,) = pump.readTwaReserves(user, startCumulativeReserves, startTimestamp);
            for (uint i = 0; i < n; i++) {
                if (reserves[i] > 1e20) {
                    assertApproxEqRel(twaReserves[i], reserves[i], 1);
                } else {
                    assertApproxEqAbs(twaReserves[i], reserves[i], 1);
                }
            }
        }
    }
}
