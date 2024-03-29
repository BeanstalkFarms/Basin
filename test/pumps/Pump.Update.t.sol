// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console, TestHelper} from "test/TestHelper.sol";
import {MultiFlowPump, ABDKMathQuad} from "src/pumps/MultiFlowPump.sol";
import {from18, to18} from "test/pumps/PumpHelpers.sol";
import {MockReserveWell} from "mocks/wells/MockReserveWell.sol";
import {IMultiFlowPumpErrors} from "src/interfaces/pumps/IMultiFlowPumpErrors.sol";

import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";

contract PumpUpdateTest is TestHelper {
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
    }

    function test_initialized() public prank(user) {
        bytes memory startCumulativeReserves = pump.readCumulativeReserves(address(mWell), new bytes(0));
        uint256 lastTimestamp = block.timestamp;
        // Last reserves are initialized with initial liquidity
        uint256[] memory lastReserves = pump.readLastCappedReserves(address(mWell));
        assertApproxEqAbs(lastReserves[0], 1e6, 1);
        assertApproxEqAbs(lastReserves[1], 2e6, 1);

        //
        uint256[] memory lastEmaReserves = pump.readLastInstantaneousReserves(address(mWell));
        assertApproxEqAbs(lastEmaReserves[0], 1e6, 1);
        assertApproxEqAbs(lastEmaReserves[1], 2e6, 1);

        // EMA reserves are initialized with initial liquidity
        uint256[] memory emaReserves = pump.readInstantaneousReserves(address(mWell), new bytes(0));
        assertApproxEqAbs(emaReserves[0], 1e6, 1);
        assertApproxEqAbs(emaReserves[1], 2e6, 1);

        // Cumulative reserves are initialized to zero
        bytes16[] memory lastCumulativeReserves = pump.readLastCumulativeReserves(address(mWell));
        assertEq(lastCumulativeReserves[0], bytes16(0));
        assertEq(lastCumulativeReserves[1], bytes16(0));

        bytes16[] memory cumulativeReserves =
            abi.decode(pump.readCumulativeReserves(address(mWell), new bytes(0)), (bytes16[]));
        assertEq(cumulativeReserves[0], bytes16(0));
        assertEq(cumulativeReserves[1], bytes16(0));

        vm.expectRevert(IMultiFlowPumpErrors.NoTimePassed.selector);
        pump.readTwaReserves(address(mWell), startCumulativeReserves, lastTimestamp, new bytes(0));
    }

    /// @dev no time has elapsed since prev update = no change
    function test_update_0Seconds() public prank(user) {
        bytes memory startCumulativeReserves = pump.readCumulativeReserves(address(mWell), new bytes(0));
        uint256 lastTimestamp = block.timestamp;
        b[0] = 2e6;
        b[1] = 1e6;
        mWell.update(address(pump), b, new bytes(0));
        mWell.update(address(pump), b, new bytes(0));

        uint256[] memory lastReserves = pump.readLastCappedReserves(address(mWell));
        assertApproxEqAbs(lastReserves[0], 1e6, 1);
        assertApproxEqAbs(lastReserves[1], 2e6, 1);

        uint256[] memory lastEmaReserves = pump.readLastInstantaneousReserves(address(mWell));
        assertApproxEqAbs(lastEmaReserves[0], 1e6, 1);
        assertApproxEqAbs(lastEmaReserves[1], 2e6, 1);

        uint256[] memory emaReserves = pump.readInstantaneousReserves(address(mWell), new bytes(0));
        assertApproxEqAbs(emaReserves[0], 1e6, 1);
        assertApproxEqAbs(emaReserves[1], 2e6, 1);

        bytes16[] memory lastCumulativeReserves = pump.readLastCumulativeReserves(address(mWell));
        assertEq(lastCumulativeReserves[0], bytes16(0));
        assertEq(lastCumulativeReserves[1], bytes16(0));

        bytes16[] memory cumulativeReserves =
            abi.decode(pump.readCumulativeReserves(address(mWell), new bytes(0)), (bytes16[]));
        assertEq(cumulativeReserves[0], bytes16(0));
        assertEq(cumulativeReserves[1], bytes16(0));

        vm.expectRevert(IMultiFlowPumpErrors.NoTimePassed.selector);
        pump.readTwaReserves(address(mWell), startCumulativeReserves, lastTimestamp, new bytes(0));
    }

    function test_update_12Seconds() public prank(user) {
        bytes memory startCumulativeReserves = pump.readCumulativeReserves(address(mWell), new bytes(0));
        // After CAP_INTERVAL, Pump receives an update
        b[0] = 2e6; // 1e6 -> 2e6 = +100%
        b[1] = 1e6; // 2e6 -> 1e6 = - 50%
        mWell.update(address(pump), b, new bytes(0));

        increaseTime(CAP_INTERVAL);

        mWell.update(address(pump), b, new bytes(0));

        //
        uint256[] memory lastReserves = pump.readLastCappedReserves(address(mWell));
        assertApproxEqAbs(lastReserves[0], 1.5e6, 1); // capped
        assertApproxEqAbs(lastReserves[1], 1e6, 1); // uncapped

        //
        uint256[] memory lastEmaReserves = pump.readLastInstantaneousReserves(address(mWell));
        assertEq(lastEmaReserves[0], 1_337_697);
        assertEq(lastEmaReserves[1], 1_216_241);

        //
        uint256[] memory emaReserves = pump.readInstantaneousReserves(address(mWell), new bytes(0));
        assertEq(emaReserves[0], 1_337_697);
        assertEq(emaReserves[1], 1_216_241);

        //
        bytes16[] memory lastCumulativeReserves = pump.readLastCumulativeReserves(address(mWell));
        assertApproxEqAbs(lastCumulativeReserves[0].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1.5e6, 1);
        assertApproxEqAbs(lastCumulativeReserves[1].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1e6, 1);

        bytes16[] memory cumulativeReserves =
            abi.decode(pump.readCumulativeReserves(address(mWell), new bytes(0)), (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1.5e6, 1);
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1e6, 1);

        (uint256[] memory twaReserves, bytes memory twaCumulativeReservesBytes) =
            pump.readTwaReserves(address(mWell), startCumulativeReserves, block.timestamp - CAP_INTERVAL, new bytes(0));

        assertApproxEqAbs(twaReserves[0], 1.5e6, 1);
        assertApproxEqAbs(twaReserves[1], 1e6, 1);

        cumulativeReserves = abi.decode(twaCumulativeReservesBytes, (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1.5e6, 1);
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1e6, 1);
    }

    function test_12Seconds_read() public prank(user) {
        bytes memory startCumulativeReserves = pump.readCumulativeReserves(address(mWell), new bytes(0));

        b[0] = 2e6; // 1e6 -> 2e6 = +100%
        b[1] = 1e6; // 2e6 -> 1e6 = - 50%
        mWell.update(address(pump), b, new bytes(0));

        increaseTime(CAP_INTERVAL);

        uint256[] memory emaReserves = pump.readInstantaneousReserves(address(mWell), new bytes(0));
        assertEq(emaReserves[0], 1_337_697);
        assertEq(emaReserves[1], 1_216_241);

        bytes16[] memory cumulativeReserves =
            abi.decode(pump.readCumulativeReserves(address(mWell), new bytes(0)), (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1.5e6, 1);
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1e6, 1);

        (uint256[] memory twaReserves, bytes memory twaCumulativeReservesBytes) =
            pump.readTwaReserves(address(mWell), startCumulativeReserves, block.timestamp - CAP_INTERVAL, new bytes(0));

        assertApproxEqAbs(twaReserves[0], 1.5e6, 1);
        assertApproxEqAbs(twaReserves[1], 1e6, 1);

        cumulativeReserves = abi.decode(twaCumulativeReservesBytes, (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1.5e6, 1);
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1e6, 1);
    }

    function test_12seconds_update_12Seconds_update() public prank(user) {
        bytes memory startCumulativeReserves = pump.readCumulativeReserves(address(mWell), new bytes(0));

        b[0] = 2e6; // 1e6 -> 2e6 = +100%
        b[1] = 1e6; // 2e6 -> 1e6 = - 50%

        mWell.update(address(pump), b, new bytes(0));

        increaseTime(CAP_INTERVAL);

        bytes memory startCumulativeReserves2 = pump.readCumulativeReserves(address(mWell), new bytes(0));

        b[0] = 1e6; // 1e6 -> 2e6 = +100%
        b[1] = 2e6; // 2e6 -> 1e6 = - 50%

        mWell.update(address(pump), b, new bytes(0));

        increaseTime(CAP_INTERVAL);

        mWell.update(address(pump), b, new bytes(0));

        //
        uint256[] memory lastReserves = pump.readLastCappedReserves(address(mWell));
        assertApproxEqAbs(lastReserves[0], 1e6, 1); // capped
        assertApproxEqAbs(lastReserves[1], 1.5e6, 1); // uncapped

        //
        uint256[] memory lastEmaReserves = pump.readLastInstantaneousReserves(address(mWell));
        assertEq(lastEmaReserves[0], 1_085_643);
        assertEq(lastEmaReserves[1], 1_413_741);

        //
        uint256[] memory emaReserves = pump.readInstantaneousReserves(address(mWell), new bytes(0));
        assertEq(emaReserves[0], 1_085_643);
        assertEq(emaReserves[1], 1_413_741);

        //
        bytes16[] memory lastCumulativeReserves = pump.readLastCumulativeReserves(address(mWell));
        assertApproxEqAbs(lastCumulativeReserves[0].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_224_744, 1);
        assertApproxEqAbs(lastCumulativeReserves[1].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_224_744, 1);

        bytes16[] memory cumulativeReserves =
            abi.decode(pump.readCumulativeReserves(address(mWell), new bytes(0)), (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_224_744, 1);
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_224_744, 1);

        (uint256[] memory twaReserves, bytes memory twaCumulativeReservesBytes) = pump.readTwaReserves(
            address(mWell), startCumulativeReserves, block.timestamp - 2 * CAP_INTERVAL, new bytes(0)
        );

        assertApproxEqAbs(twaReserves[0], 1_224_744, 1);
        assertApproxEqAbs(twaReserves[1], 1_224_744, 1);

        cumulativeReserves = abi.decode(twaCumulativeReservesBytes, (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_224_744, 1);
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_224_744, 1);

        (twaReserves, twaCumulativeReservesBytes) =
            pump.readTwaReserves(address(mWell), startCumulativeReserves2, block.timestamp - CAP_INTERVAL, new bytes(0));

        assertApproxEqAbs(twaReserves[0], 1e6, 1);
        assertApproxEqAbs(twaReserves[1], 1.5e6, 1);

        cumulativeReserves = abi.decode(twaCumulativeReservesBytes, (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_224_744, 1);
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_224_744, 1);
    }

    function test_12seconds_update_12Seconds_read() public prank(user) {
        bytes memory startCumulativeReserves = pump.readCumulativeReserves(address(mWell), new bytes(0));

        b[0] = 2e6; // 1e6 -> 2e6 = +100%
        b[1] = 1e6; // 2e6 -> 1e6 = - 50%

        mWell.update(address(pump), b, new bytes(0));

        increaseTime(CAP_INTERVAL);

        bytes memory startCumulativeReserves2 = pump.readCumulativeReserves(address(mWell), new bytes(0));

        b[0] = 1e6; // 1e6 -> 2e6 = +100%
        b[1] = 2e6; // 2e6 -> 1e6 = - 50%

        mWell.update(address(pump), b, new bytes(0));

        increaseTime(CAP_INTERVAL);

        uint256[] memory emaReserves = pump.readInstantaneousReserves(address(mWell), new bytes(0));
        assertEq(emaReserves[0], 1_085_643);
        assertEq(emaReserves[1], 1_413_741);

        bytes16[] memory cumulativeReserves =
            abi.decode(pump.readCumulativeReserves(address(mWell), new bytes(0)), (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_224_744, 1);
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_224_744, 1);

        (uint256[] memory twaReserves, bytes memory twaCumulativeReservesBytes) = pump.readTwaReserves(
            address(mWell), startCumulativeReserves, block.timestamp - 2 * CAP_INTERVAL, new bytes(0)
        );

        assertApproxEqAbs(twaReserves[0], 1_224_744, 1);
        assertApproxEqAbs(twaReserves[1], 1_224_744, 1);

        cumulativeReserves = abi.decode(twaCumulativeReservesBytes, (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_224_744, 1);
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_224_744, 1);

        (twaReserves, twaCumulativeReservesBytes) =
            pump.readTwaReserves(address(mWell), startCumulativeReserves2, block.timestamp - CAP_INTERVAL, new bytes(0));

        assertApproxEqAbs(twaReserves[0], 1e6, 1);
        assertApproxEqAbs(twaReserves[1], 1.5e6, 1);

        cumulativeReserves = abi.decode(twaCumulativeReservesBytes, (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_224_744, 1);
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_224_744, 1);
    }
}
