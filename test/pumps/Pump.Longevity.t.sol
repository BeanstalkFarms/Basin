/**
 * SPDX-License-Identifier: MIT
 *
 */
pragma solidity ^0.8.17;

import {console, TestHelper} from "test/TestHelper.sol";
import {ABDKMathQuad, GeoEmaAndCumSmaPump} from "src/pumps/GeoEmaAndCumSmaPump.sol";
import {MockReserveWell} from "mocks/wells/MockReserveWell.sol";

import {generateRandomUpdate, from18, to18} from "test/pumps/PumpHelpers.sol";
import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";

contract PumpFuzzTest is TestHelper {

    using ABDKMathQuad for bytes16;
    using ABDKMathQuad for uint;

    GeoEmaAndCumSmaPump pump;
    MockReserveWell mWell;
    uint[] b = new uint[](2);

    constructor()
    {}

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

    function testIterate() public prank(user) {
        bytes32 seed = bytes32(0);
        uint n = 2;
        uint[] memory balances;
        uint40 timeStep;
        uint timestamp = block.timestamp;
        for (uint i; i < 30000; ++i) {
            (balances, timeStep, seed) = generateRandomUpdate(n, seed);
            // console.log("Time Step: ", timeStep);
            // for (uint j; j < n; ++j) {
            //     console.log("Balance", j, balances[j]);
            // }
            increaseTime(timeStep);
            mWell.update(address(pump), balances, new bytes(0));
        }

        uint[] memory lastReserves = pump.readLastReserves(address(mWell));
        uint[] memory currentReserves = pump.readInstantaneousReserves(address(mWell));
        bytes16[] memory lastCumulativeReserves = pump.readLastCumulativeReserves(address(mWell));

        // TODO: Add tests revolving around a subsequent update.
        // for (uint i; i < n; ++i) {
        //     console.log("Reserve", i, balances[i]);
        //     console.log("Last Reserve", i, lastReserves[i]);
        //     console.log("Current Reserve", i, currentReserves[i]);
        //     console.logBytes16(lastCumulativeReserves[i]);
        // }
        uint deltaTimestamp = block.timestamp - timestamp;
        console.log("Time passed:", deltaTimestamp / 60 / 60 / 24 / 365, "years");
    }
}
