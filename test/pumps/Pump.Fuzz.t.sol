/**
 * SPDX-License-Identifier: MIT
 *
 */
pragma solidity ^0.8.20;

import {console, TestHelper} from "test/TestHelper.sol";
import {ABDKMathQuad, MultiFlowPump} from "src/pumps/MultiFlowPump.sol";
import {MockReserveWell} from "mocks/wells/MockReserveWell.sol";

import {mockPumpData, from18, to18} from "test/pumps/PumpHelpers.sol";
import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";

import {Math} from "oz/utils/math/Math.sol";

contract PumpFuzzTest is TestHelper, MultiFlowPump {
    using ABDKMathQuad for bytes16;
    using ABDKMathQuad for uint256;
    using Math for uint256;

    uint256 constant capInterval = 12;
    MultiFlowPump pump;
    bytes data;
    MockReserveWell mWell;
    uint256[] b = new uint256[](2);

    constructor() MultiFlowPump() {}

    function setUp() public {
        mWell = new MockReserveWell();
        initUser();
        pump = new MultiFlowPump();
        data = mockPumpData();
        wellFunction.target = address(new ConstantProduct2());
        mWell.setWellFunction(wellFunction);
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
        // n is bound to 2 in the current iteration of the well.
        // n = uint8(bound(n, 1, 8));
        n = 2;
        for (uint256 i; i < n; i++) {
            initReserves[i] = bound(initReserves[i], 1e6, 1e32);
            reserves[i] = bound(reserves[i], 1e6, 1e32);
        }

        // timeIncrease = 1099511627775; //1099511627775 is max uint40

        vm.assume(block.timestamp + timeIncrease <= type(uint40).max);

        // Start by updating the Pump with the initial reserves. Also initializes the Pump.
        uint256[] memory updateReserves = new uint256[](n);
        for (uint256 i; i < n; i++) {
            updateReserves[i] = initReserves[i];
        }
        mWell.update(address(pump), updateReserves, data);
        for (uint256 i; i < n; i++) {
            updateReserves[i] = reserves[i];
        }
        mWell.update(address(pump), updateReserves, data);

        // Read a snapshot from the Pump
        bytes memory startCumulativeReserves = pump.readCumulativeReserves(address(mWell), data);

        uint256[] memory expectedCappedReserves = pump.readLastCappedReserves(address(mWell), data);

        // Fast-forward time and update the Pump with new reserves.
        increaseTime(timeIncrease);
        uint256[] memory cappedReserves = pump.readCappedReserves(address(mWell), data);

        mWell.update(address(pump), updateReserves, data);

        uint256[] memory lastReserves = pump.readLastCappedReserves(address(mWell), data);

        uint256[] memory _reserves = new uint256[](n);

        for (uint256 i; i < n; ++i) {
            _reserves[i] = reserves[i];
        }

        (,, CapReservesParameters memory crp) = abi.decode(data, (uint256, uint256, CapReservesParameters));
        if (timeIncrease > 0) {
            uint256 capExponent = (timeIncrease - 1) / capInterval + 1;
            expectedCappedReserves = _capReserves(address(mWell), expectedCappedReserves, _reserves, capExponent, crp);
        }

        for (uint256 i; i < n; ++i) {
            if (lastReserves[i] > 1e24) {
                assertApproxEqRelN(expectedCappedReserves[i], lastReserves[i], 1, 24);
                assertApproxEqRelN(expectedCappedReserves[i], cappedReserves[i], 1, 24);
            } else {
                assertApproxEqAbs(expectedCappedReserves[i], lastReserves[i], 1);
                assertApproxEqAbs(expectedCappedReserves[i], cappedReserves[i], 1);
            }
        }

        // readTwaReserves reverts if no time has passed.
        if (timeIncrease > 0) {
            (uint256[] memory twaReserves,) =
                pump.readTwaReserves(address(mWell), startCumulativeReserves, block.timestamp - timeIncrease, data);
            for (uint256 i; i < n; ++i) {
                console.log("TWA RESERVES", i, twaReserves[i]);
                if (lastReserves[i] > 1e24) {
                    assertApproxEqRelN(twaReserves[i], lastReserves[i], 1, 24);
                } else {
                    assertApproxEqAbs(twaReserves[i], lastReserves[i], 1);
                }
            }
        }
        // assertTrue(false);
    }
}
