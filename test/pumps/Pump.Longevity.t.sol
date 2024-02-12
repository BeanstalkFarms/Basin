/**
 * SPDX-License-Identifier: MIT
 *
 */
pragma solidity ^0.8.20;

import {console, TestHelper} from "test/TestHelper.sol";
import {ABDKMathQuad, MultiFlowPump} from "src/pumps/MultiFlowPump.sol";
import {MockReserveWell} from "mocks/wells/MockReserveWell.sol";
import {mockPumpData} from "test/pumps/PumpHelpers.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";

import {generateRandomUpdate, from18, to18} from "test/pumps/PumpHelpers.sol";
import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";

contract PumpLongevityTest is TestHelper {
    using ABDKMathQuad for bytes16;
    using ABDKMathQuad for uint256;

    MultiFlowPump pump;
    MockReserveWell mWell;
    bytes data;
    uint256[] b = new uint256[](2);

    constructor() {}

    function setUp() public {
        mWell = new MockReserveWell();
        initUser();
        pump = new MultiFlowPump();
        data = mockPumpData();
        wellFunction.target = address(new ConstantProduct2());
        mWell.setWellFunction(wellFunction);
    }

    function testIterate() public prank(user) {
        bytes32 seed = bytes32(0);
        uint256 n = 2;
        uint256[] memory balances;
        uint40 timeStep;
        uint256 timestamp = block.timestamp;
        for (uint256 i; i < 4000; ++i) {
            if (i % 1000 == 0) {
                console.log(i);
            }
            (balances, timeStep, seed) = generateRandomUpdate(n, seed);
            // console.log("Time Step: ", timeStep);
            // for (uint256 j; j < n; ++j) {
            //     console.log("Balance", j, balances[j]);
            // }
            increaseTime(timeStep);
            mWell.update(address(pump), balances, data);
        }

        // uint256[] memory lastReserves = pump.readLastReserves(address(mWell));
        // uint256[] memory currentReserves = pump.readInstantaneousReserves(address(mWell));
        // bytes16[] memory lastCumulativeReserves = pump.readLastCumulativeReserves(address(mWell));

        // for (uint256 i; i < n; ++i) {
        //     console.log("Reserve", i, balances[i]);
        //     console.log("Last Reserve", i, lastReserves[i]);
        //     console.log("Current Reserve", i, currentReserves[i]);
        //     console.logBytes16(lastCumulativeReserves[i]);
        // }
        uint256 deltaTimestamp = block.timestamp - timestamp;
        console.log("Time passed:", deltaTimestamp / 60 / 60 / 24 / 365, "years");
    }
}
