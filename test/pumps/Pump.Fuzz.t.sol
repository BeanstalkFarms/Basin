/**
 * SPDX-License-Identifier: MIT
 *
 */
pragma solidity ^0.8.17;

import {console, TestHelper} from "test/TestHelper.sol";
import {ABDKMathQuad, GeoEmaAndCumSmaPump} from "src/pumps/GeoEmaAndCumSmaPump.sol";
import {MockReserveWell} from "mocks/wells/MockReserveWell.sol";

import {from18, to18} from "test/pumps/PumpHelpers.sol";
import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";

contract PumpFuzzTest is TestHelper, GeoEmaAndCumSmaPump {
    using ABDKMathQuad for bytes16;
    using ABDKMathQuad for uint;

    GeoEmaAndCumSmaPump pump;
    MockReserveWell mWell;
    uint[] b = new uint[](2);

    constructor() GeoEmaAndCumSmaPump(from18(0.5e18), from18(0.333333333333333333e18), 12, from18(0.9e18)) {}

    function setUp() public {
        mWell = new MockReserveWell();
        initUser();
        pump = new GeoEmaAndCumSmaPump(
            from18(0.5e18),
            from18(0.333333333333333333e18),
            12,
            from18(0.9e18)
        );
    }

    function testFuzz_update(
        uint[8] memory initReserves,
        uint[8] memory reserves,
        uint8 n,
        uint40 timeIncrease,
        uint40 timeIncrease2
    ) public prank(user) {
        n = uint8(bound(n, 1, 8));
        for (uint i = 0; i < n; i++) {
            // TODO: relax min assumption
            initReserves[i] = bound(initReserves[i], 1e6, type(uint128).max);
            reserves[i] = bound(reserves[i], 1e6, type(uint128).max);
        }
        // timeIncrease = uint40(bound(timeIncrease, 1, type(uint40).max - block.timestamp));
        // timeIncrease2 = uint40(bound(timeIncrease2, 1, type(uint40).max - block.timestamp - timeIncrease));
        vm.assume(block.timestamp + timeIncrease + timeIncrease2 <= type(uint40).max);

        uint[] memory updateReserves = new uint[](n);
        for (uint i = 0; i < n; i++) {
            updateReserves[i] = initReserves[i];
        }

        mWell.update(address(pump), updateReserves, new bytes(0));

        bytes memory startCumulativeReserves = pump.readCumulativeReserves(address(mWell));
        uint startTimestamp = block.timestamp;

        for (uint i = 0; i < n; i++) {
            updateReserves[i] = reserves[i];
        }

        increaseTime(timeIncrease);
        mWell.update(address(pump), updateReserves, new bytes(0));

        uint[] memory lastReserves = pump.readLastReserves(address(mWell));

        for (uint i; i < n; ++i) {
            uint capReserve = _capReserve(
                initReserves[i].fromUIntToLog2(),
                updateReserves[i].fromUIntToLog2(),
                (timeIncrease / BLOCK_TIME).fromUInt()
            ).pow_2ToUInt();
            if (lastReserves[i] > 1e20) {
                assertApproxEqRelN(capReserve, lastReserves[i], 1, 24);
            } else {
                assertApproxEqAbs(capReserve, lastReserves[i], 1);
            }
        }

        // readTwaReserves reverts if no time has passed.
        if (timeIncrease > 0) {
            (uint[] memory twaReserves,) = pump.readTwaReserves(address(mWell), startCumulativeReserves, startTimestamp);
            for (uint i; i < n; ++i) {
                console.log("TWA RESERVES", i, twaReserves[i]);
                if (lastReserves[i] > 1e20) {
                    assertApproxEqRelN(twaReserves[i], lastReserves[i], 1, 24);
                } else {
                    assertApproxEqAbs(twaReserves[i], lastReserves[i], 1);
                }
            }
        }
    }
}
