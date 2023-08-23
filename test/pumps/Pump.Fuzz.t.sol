/**
 * SPDX-License-Identifier: MIT
 *
 */
pragma solidity ^0.8.20;

import {console, TestHelper} from "test/TestHelper.sol";
import {ABDKMathQuad, MultiFlowPump} from "src/pumps/MultiFlowPump.sol";
import {MockReserveWell} from "mocks/wells/MockReserveWell.sol";

import {from18, to18} from "test/pumps/PumpHelpers.sol";
import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";

contract PumpFuzzTest is TestHelper, MultiFlowPump {
    using ABDKMathQuad for bytes16;
    using ABDKMathQuad for uint256;

    MultiFlowPump pump;
    MockReserveWell mWell;
    uint256[] b = new uint256[](2);

    constructor() MultiFlowPump(from18(0.5e18), from18(0.333333333333333333e18), 12, from18(0.9e18)) {}

    function setUp() public {
        mWell = new MockReserveWell();
        initUser();
        pump = new MultiFlowPump(
            from18(0.5e18),
            from18(0.333333333333333333e18),
            12,
            from18(0.9e18)
        );
    }

    /**
     * @dev Reserves precision:
     *
     * When reserves are <= 1e24, we accept an absolute error of 1.
     * When reserves are > 1e24, we accept a relative error of 1e-24.
     * i.e. the maximum delta between actual and expected reserves is:
     * 1 - (1e24)/(1e24 + 1)
     */
    function testFuzz_update(
        uint256[8] memory initReserves,
        uint256[8] memory reserves,
        uint8 n,
        uint40 timeIncrease
    ) public prank(user) {
        n = uint8(bound(n, 1, 8));
        for (uint256 i; i < n; i++) {
            initReserves[i] = bound(initReserves[i], 1e6, type(uint128).max);
            reserves[i] = bound(reserves[i], 1e6, type(uint128).max);
        }
        vm.assume(block.timestamp + timeIncrease <= type(uint40).max);

        // Start by updating the Pump with the initial reserves. Also initializes the Pump.
        uint256[] memory updateReserves = new uint256[](n);
        for (uint256 i; i < n; i++) {
            updateReserves[i] = initReserves[i];
        }
        mWell.update(address(pump), updateReserves, new bytes(0));
        for (uint256 i; i < n; i++) {
            updateReserves[i] = reserves[i];
        }
        mWell.update(address(pump), updateReserves, new bytes(0));

        // Read a snapshot from the Pump
        bytes memory startCumulativeReserves = pump.readCumulativeReserves(address(mWell), new bytes(0));

        // Fast-forward time and update the Pump with new reserves.
        increaseTime(timeIncrease);
        uint256[] memory cappedReserves = pump.readCappedReserves(address(mWell));

        mWell.update(address(pump), updateReserves, new bytes(0));

        uint256[] memory lastReserves = pump.readLastCappedReserves(address(mWell));

        for (uint256 i; i < n; ++i) {
            uint256 capReserve;
            if (timeIncrease > 0) {
                capReserve = _capReserve(
                    initReserves[i].fromUIntToLog2(),
                    updateReserves[i].fromUIntToLog2(),
                    ((timeIncrease - 1) / CAP_INTERVAL + 1).fromUInt()
                ).pow_2ToUInt();
            } else {
                capReserve = initReserves[i];
            }

            if (lastReserves[i] > 1e24) {
                assertApproxEqRelN(capReserve, lastReserves[i], 1, 24);
                assertApproxEqRelN(capReserve, cappedReserves[i], 1, 24);
            } else {
                assertApproxEqAbs(capReserve, lastReserves[i], 1);
                assertApproxEqAbs(capReserve, cappedReserves[i], 1);
            }
        }

        // readTwaReserves reverts if no time has passed.
        if (timeIncrease > 0) {
            (uint256[] memory twaReserves,) = pump.readTwaReserves(
                address(mWell), startCumulativeReserves, block.timestamp - timeIncrease, new bytes(0)
            );
            for (uint256 i; i < n; ++i) {
                console.log("TWA RESERVES", i, twaReserves[i]);
                if (lastReserves[i] > 1e24) {
                    assertApproxEqRelN(twaReserves[i], lastReserves[i], 1, 24);
                } else {
                    assertApproxEqAbs(twaReserves[i], lastReserves[i], 1);
                }
            }
        }
    }
}
