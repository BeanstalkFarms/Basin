// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console, TestHelper} from "test/TestHelper.sol";
import {MultiFlowPump, ABDKMathQuad} from "src/pumps/MultiFlowPump.sol";
import {from18, to18} from "test/pumps/PumpHelpers.sol";
import {MockReserveWell} from "mocks/wells/MockReserveWell.sol";

import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";

contract PumpTimeWeightedAverageTest is TestHelper {
    using ABDKMathQuad for bytes16;

    MultiFlowPump pump;
    MockReserveWell mWell;
    uint256[] b = new uint256[](2);

    uint256 constant CAP_INTERVAL = 12;

    /// @dev for this test, `user` = a Well that's calling the Pump
    function setUp() public {
        mWell = new MockReserveWell();
        initUser();
        pump = new MultiFlowPump(
            from18(0.5e18), // cap reserves if changed +/- 50% per block
            from18(0.5e18), // cap reserves if changed +/- 50% per block
            12, // block time
            from18(0.9e18) // ema alpha
        );

        // Send first update to the Pump, which will initialize it
        vm.prank(user);
        b[0] = 1e6;
        b[1] = 2e6;
        mWell.update(address(pump), b, new bytes(0));
        mWell.update(address(pump), b, new bytes(0));

        uint256[] memory checkReserves = mWell.getReserves();
        assertEq(checkReserves[0], b[0]);
        assertEq(checkReserves[1], b[1]);
    }

    function testTWAReserves() public prank(user) {
        increaseTime(12);

        bytes memory startCumulativeReserves = pump.readCumulativeReserves(address(mWell), "");
        uint256[] memory lastReserves = pump.readLastCappedReserves(address(mWell));

        assertApproxEqAbs(lastReserves[0], 1e6, 1);
        assertApproxEqAbs(lastReserves[1], 2e6, 1);

        increaseTime(120);
        uint256[] memory twaReserves;

        (twaReserves,) = pump.readTwaReserves(address(mWell), startCumulativeReserves, block.timestamp - 120, "");

        assertApproxEqAbs(twaReserves[0], 1e6, 1);
        assertApproxEqAbs(twaReserves[1], 2e6, 1);

        b[0] = 2e6;
        b[1] = 4e6;
        mWell.update(address(pump), b, new bytes(0));

        increaseTime(120);

        (twaReserves,) = pump.readTwaReserves(address(mWell), startCumulativeReserves, block.timestamp - 240, "");

        assertEq(twaReserves[0], 1_414_213); // Geometric Mean of 1e6 and 2e6 is 1_414_213
        assertEq(twaReserves[1], 2_828_427); // Geometric mean of 2e6 and 4e6 is 2_828_427
    }
}
