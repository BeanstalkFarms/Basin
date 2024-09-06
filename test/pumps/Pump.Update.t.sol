// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console, TestHelper} from "test/TestHelper.sol";
import {MultiFlowPump, ABDKMathQuad} from "src/pumps/MultiFlowPump.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";
import {from18, to18, mockPumpData} from "test/pumps/PumpHelpers.sol";
import {MockReserveWell} from "mocks/wells/MockReserveWell.sol";
import {IMultiFlowPumpErrors} from "src/interfaces/pumps/IMultiFlowPumpErrors.sol";

import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";

contract PumpUpdateTest is TestHelper {
    using ABDKMathQuad for bytes16;

    MultiFlowPump pump;
    bytes data;
    MockReserveWell mWell;
    uint256[] b = new uint256[](2);

    uint256 constant CAP_INTERVAL = 12;

    /// @dev for this test, `user` = a Well that's calling the Pump
    function setUp() public {
        mWell = new MockReserveWell();
        initUser();
        pump = new MultiFlowPump();
        data = mockPumpData();
        wellFunction.target = address(new ConstantProduct2());
        mWell.setWellFunction(wellFunction);

        // Send first update to the Pump, which will initialize it
        vm.prank(user);
        b[0] = 1e6;
        b[1] = 2e6;
        mWell.update(address(pump), b, data);
        mWell.update(address(pump), b, data);
    }

    function test_initialized() public prank(user) {
        bytes memory startCumulativeReserves = pump.readCumulativeReserves(address(mWell), data);
        uint256 lastTimestamp = block.timestamp;
        // Last reserves are initialized with initial liquidity
        uint256[] memory lastReserves = pump.readLastCappedReserves(address(mWell), data);
        assertApproxEqAbs(lastReserves[0], 1e6, 1);
        assertApproxEqAbs(lastReserves[1], 2e6, 1);

        //
        uint256[] memory lastEmaReserves = pump.readLastInstantaneousReserves(address(mWell), data);
        assertApproxEqAbs(lastEmaReserves[0], 1e6, 1);
        assertApproxEqAbs(lastEmaReserves[1], 2e6, 1);

        // EMA reserves are initialized with initial liquidity
        uint256[] memory emaReserves = pump.readInstantaneousReserves(address(mWell), data);
        assertApproxEqAbs(emaReserves[0], 1e6, 1);
        assertApproxEqAbs(emaReserves[1], 2e6, 1);

        // Cumulative reserves are initialized to zero
        bytes16[] memory lastCumulativeReserves = pump.readLastCumulativeReserves(address(mWell), data);
        assertEq(lastCumulativeReserves[0], bytes16(0));
        assertEq(lastCumulativeReserves[1], bytes16(0));

        bytes16[] memory cumulativeReserves = abi.decode(pump.readCumulativeReserves(address(mWell), data), (bytes16[]));
        assertEq(cumulativeReserves[0], bytes16(0));
        assertEq(cumulativeReserves[1], bytes16(0));

        vm.expectRevert(IMultiFlowPumpErrors.NoTimePassed.selector);
        pump.readTwaReserves(address(mWell), startCumulativeReserves, lastTimestamp, data);
    }

    /// @dev no time has elapsed since prev update = no change
    function test_update_0Seconds() public prank(user) {
        bytes memory startCumulativeReserves = pump.readCumulativeReserves(address(mWell), data);
        uint256 lastTimestamp = block.timestamp;
        b[0] = 2e6;
        b[1] = 1e6;
        mWell.update(address(pump), b, data);
        mWell.update(address(pump), b, data);

        uint256[] memory lastReserves = pump.readLastCappedReserves(address(mWell), data);
        assertApproxEqAbs(lastReserves[0], 1e6, 1);
        assertApproxEqAbs(lastReserves[1], 2e6, 1);

        uint256[] memory lastEmaReserves = pump.readLastInstantaneousReserves(address(mWell), data);
        assertApproxEqAbs(lastEmaReserves[0], 1e6, 1);
        assertApproxEqAbs(lastEmaReserves[1], 2e6, 1);

        uint256[] memory emaReserves = pump.readInstantaneousReserves(address(mWell), data);
        assertApproxEqAbs(emaReserves[0], 1e6, 1);
        assertApproxEqAbs(emaReserves[1], 2e6, 1);

        bytes16[] memory lastCumulativeReserves = pump.readLastCumulativeReserves(address(mWell), data);
        assertEq(lastCumulativeReserves[0], bytes16(0));
        assertEq(lastCumulativeReserves[1], bytes16(0));

        bytes16[] memory cumulativeReserves = abi.decode(pump.readCumulativeReserves(address(mWell), data), (bytes16[]));
        assertEq(cumulativeReserves[0], bytes16(0));
        assertEq(cumulativeReserves[1], bytes16(0));

        vm.expectRevert(IMultiFlowPumpErrors.NoTimePassed.selector);
        pump.readTwaReserves(address(mWell), startCumulativeReserves, lastTimestamp, data);
    }

    function test_update_12Seconds() public prank(user) {
        bytes memory startCumulativeReserves = pump.readCumulativeReserves(address(mWell), data);
        // After CAP_INTERVAL, Pump receives an update
        b[0] = 2e6; // 1e6 -> 2e6 = +100%
        b[1] = 1e6; // 2e6 -> 1e6 = - 50%
        mWell.update(address(pump), b, data);

        increaseTime(CAP_INTERVAL);

        mWell.update(address(pump), b, data);

        //
        uint256[] memory lastReserves = pump.readLastCappedReserves(address(mWell), data);
        assertApproxEqAbs(lastReserves[0], 1_224_743, 1);
        assertApproxEqAbs(lastReserves[1], 1_632_992, 1);

        //
        uint256[] memory lastEmaReserves = pump.readLastInstantaneousReserves(address(mWell), data);
        assertApproxEqAbs(lastEmaReserves[0], 1_156_587, 1); // = 2^(log2(1000000) * 0.9^12 +log2(1224743) * (1-0.9^12))
        assertApproxEqAbs(lastEmaReserves[1], 1_729_223, 1); // = 2^(log2(2000000) * 0.9^12 +log2(1632992) * (1-0.9^12))

        //
        uint256[] memory emaReserves = pump.readInstantaneousReserves(address(mWell), data);
        assertApproxEqAbs(emaReserves[0], 1_156_587, 1); // = 2^(log2(1000000) * 0.9^12 +log2(1224743) * (1-0.9^12))
        assertApproxEqAbs(emaReserves[1], 1_729_223, 1); // = 2^(log2(2000000) * 0.9^12 +log2(1632992) * (1-0.9^12))

        //
        bytes16[] memory lastCumulativeReserves = pump.readLastCumulativeReserves(address(mWell), data);
        assertApproxEqAbs(lastCumulativeReserves[0].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1_224_743, 1);
        assertApproxEqAbs(lastCumulativeReserves[1].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1_632_992, 1);

        bytes16[] memory cumulativeReserves = abi.decode(pump.readCumulativeReserves(address(mWell), data), (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1_224_743, 1);
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1_632_992, 1);

        (uint256[] memory twaReserves, bytes memory twaCumulativeReservesBytes) =
            pump.readTwaReserves(address(mWell), startCumulativeReserves, block.timestamp - CAP_INTERVAL, data);

        assertApproxEqAbs(twaReserves[0], 1_224_743, 1);
        assertApproxEqAbs(twaReserves[1], 1_632_992, 1);

        cumulativeReserves = abi.decode(twaCumulativeReservesBytes, (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1_224_743, 1);
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1_632_992, 1);
    }

    function test_12Seconds_read() public prank(user) {
        bytes memory startCumulativeReserves = pump.readCumulativeReserves(address(mWell), data);

        b[0] = 2e6; // 1e6 -> 2e6 = +100%
        b[1] = 1e6; // 2e6 -> 1e6 = - 50%
        mWell.update(address(pump), b, data);

        increaseTime(CAP_INTERVAL);
        uint256[] memory emaReserves = pump.readInstantaneousReserves(address(mWell), data);
        assertEq(emaReserves.length, 2);
        assertApproxEqAbs(emaReserves[0], 1_156_587, 1); // = 2^(log2(1000000) * 0.9^12 +log2(1224743) * (1-0.9^12))
        assertApproxEqAbs(emaReserves[1], 1_729_223, 1); // = 2^(log2(2000000) * 0.9^12 +log2(1632992) * (1-0.9^12))

        bytes16[] memory cumulativeReserves = abi.decode(pump.readCumulativeReserves(address(mWell), data), (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1_224_743, 1);
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1_632_992, 1);

        (uint256[] memory twaReserves, bytes memory twaCumulativeReservesBytes) =
            pump.readTwaReserves(address(mWell), startCumulativeReserves, block.timestamp - CAP_INTERVAL, data);

        assertEq(twaReserves.length, 2);
        assertApproxEqAbs(twaReserves[0], 1_224_743, 1);
        assertApproxEqAbs(twaReserves[1], 1_632_992, 1);

        cumulativeReserves = abi.decode(twaCumulativeReservesBytes, (bytes16[]));
        assertEq(cumulativeReserves.length, 2);
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1_224_743, 1);
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1_632_992, 1);
    }

    function test_12seconds_update_12Seconds_update() public prank(user) {
        bytes memory startCumulativeReserves = pump.readCumulativeReserves(address(mWell), data);

        b[0] = 2e6; // 1e6 -> 2e6 = +100%
        b[1] = 1e6; // 2e6 -> 1e6 = - 50%

        mWell.update(address(pump), b, data);

        increaseTime(CAP_INTERVAL);

        bytes memory startCumulativeReserves2 = pump.readCumulativeReserves(address(mWell), data);

        b[0] = 1e6; // 1e6 -> 2e6 = - 50%
        b[1] = 2e6; // 2e6 -> 1e6 = +100%

        mWell.update(address(pump), b, data);

        increaseTime(CAP_INTERVAL);

        mWell.update(address(pump), b, data);

        //
        uint256[] memory lastReserves = pump.readLastCappedReserves(address(mWell), data);
        assertApproxEqAbs(lastReserves[0], 1e6, 1); // capped
        assertApproxEqAbs(lastReserves[1], 2e6, 1); // uncapped

        //
        uint256[] memory lastEmaReserves = pump.readLastInstantaneousReserves(address(mWell), data);
        assertEq(lastEmaReserves[0], 1_041_941); // = 2^(log2(1156587) * 0.9^12 +log2(1000000) * (1-0.9^12))
        assertEq(lastEmaReserves[1], 1_919_492); // = 2^(log2(1729223) * 0.9^12 +log2(2000000) * (1-0.9^12))

        //
        uint256[] memory emaReserves = pump.readInstantaneousReserves(address(mWell), data);
        assertEq(emaReserves[0], 1_041_941); // = 2^(log2(1156587) * 0.9^12 +log2(1000000) * (1-0.9^12))
        assertEq(emaReserves[1], 1_919_492); // = 2^(log2(1729223) * 0.9^12 +log2(2000000) * (1-0.9^12))

        //
        bytes16[] memory lastCumulativeReserves = pump.readLastCumulativeReserves(address(mWell), data);
        assertApproxEqAbs(lastCumulativeReserves[0].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_106_681, 1); // = 2^((log2(1632992) * 12 + log2(2000000) * 12) / (12 + 12))
        assertApproxEqAbs(lastCumulativeReserves[1].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_807_203, 1); // = 2^((log2(1224743) * 12 + log2(1000000) * 12) / (12 + 12))

        bytes16[] memory cumulativeReserves = abi.decode(pump.readCumulativeReserves(address(mWell), data), (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_106_681, 1); // = 2^((log2(1632992) * 12 + log2(2000000) * 12) / (12 + 12))
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_807_203, 1); // = 2^((log2(1224743) * 12 + log2(1000000) * 12) / (12 + 12))

        (uint256[] memory twaReserves, bytes memory twaCumulativeReservesBytes) =
            pump.readTwaReserves(address(mWell), startCumulativeReserves, block.timestamp - 2 * CAP_INTERVAL, data);

        assertApproxEqAbs(twaReserves[0], 1_106_681, 1); // = 2^((log2(1632992) * 12 + log2(2000000) * 12) / (12 + 12))
        assertApproxEqAbs(twaReserves[1], 1_807_203, 1); // = 2^((log2(1224743) * 12 + log2(1000000) * 12) / (12 + 12))

        cumulativeReserves = abi.decode(twaCumulativeReservesBytes, (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_106_681, 1); // = 2^((log2(1632992) * 12 + log2(2000000) * 12) / (12 + 12))
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_807_203, 1); // = 2^((log2(1224743) * 12 + log2(1000000) * 12) / (12 + 12))

        (twaReserves, twaCumulativeReservesBytes) =
            pump.readTwaReserves(address(mWell), startCumulativeReserves2, block.timestamp - CAP_INTERVAL, data);

        assertApproxEqAbs(twaReserves[0], 1e6, 1);
        assertApproxEqAbs(twaReserves[1], 2e6, 1);

        cumulativeReserves = abi.decode(twaCumulativeReservesBytes, (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_106_681, 1); // = 2^((log2(1632992) * 12 + log2(2000000) * 12) / (12 + 12))
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_807_203, 1); // = 2^((log2(1224743) * 12 + log2(1000000) * 12) / (12 + 12))
    }

    function test_12seconds_update_12Seconds_read() public prank(user) {
        bytes memory startCumulativeReserves = pump.readCumulativeReserves(address(mWell), data);

        b[0] = 2e6; // 1e6 -> 2e6 = +100%
        b[1] = 1e6; // 2e6 -> 1e6 = - 50%

        mWell.update(address(pump), b, data);

        increaseTime(CAP_INTERVAL);

        bytes memory startCumulativeReserves2 = pump.readCumulativeReserves(address(mWell), data);

        b[0] = 1e6; // 1e6 -> 2e6 = - 50%
        b[1] = 2e6; // 2e6 -> 1e6 = +100%

        mWell.update(address(pump), b, data);

        increaseTime(CAP_INTERVAL);

        uint256[] memory lastReserves = pump.readCappedReserves(address(mWell), data);

        assertApproxEqAbs(lastReserves[0], 1e6, 1);
        assertApproxEqAbs(lastReserves[1], 2e6, 1);

        uint256[] memory emaReserves = pump.readInstantaneousReserves(address(mWell), data);
        assertEq(emaReserves[0], 1_041_941); // = 2^(log2(1156587) * 0.9^12 +log2(1000000) * (1-0.9^12))
        assertEq(emaReserves[1], 1_919_492); // = 2^(log2(1729223) * 0.9^12 +log2(2000000) * (1-0.9^12))

        bytes16[] memory cumulativeReserves = abi.decode(pump.readCumulativeReserves(address(mWell), data), (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_106_681, 1); // = 2^((log2(1632992) * 12 + log2(2000000) * 12) / (12 + 12))
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_807_203, 1); // = 2^((log2(1224743) * 12 + log2(1000000) * 12) / (12 + 12))

        (uint256[] memory twaReserves, bytes memory twaCumulativeReservesBytes) =
            pump.readTwaReserves(address(mWell), startCumulativeReserves, block.timestamp - 2 * CAP_INTERVAL, data);

        assertApproxEqAbs(twaReserves[0], 1_106_681, 1); // = 2^((log2(1632992) * 12 + log2(2000000) * 12) / (12 + 12))
        assertApproxEqAbs(twaReserves[1], 1_807_203, 1); // = 2^((log2(1224743) * 12 + log2(1000000) * 12) / (12 + 12))

        cumulativeReserves = abi.decode(twaCumulativeReservesBytes, (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_106_681, 1); // = 2^((log2(1632992) * 12 + log2(2000000) * 12) / (12 + 12))
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_807_203, 1); // = 2^((log2(1224743) * 12 + log2(1000000) * 12) / (12 + 12))

        (twaReserves, twaCumulativeReservesBytes) =
            pump.readTwaReserves(address(mWell), startCumulativeReserves2, block.timestamp - CAP_INTERVAL, data);

        assertApproxEqAbs(twaReserves[0], 1e6, 1);
        assertApproxEqAbs(twaReserves[1], 2e6, 1);

        cumulativeReserves = abi.decode(twaCumulativeReservesBytes, (bytes16[]));
        assertApproxEqAbs(cumulativeReserves[0].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_106_681, 1); // = 2^((log2(1632992) * 12 + log2(2000000) * 12) / (12 + 12))
        assertApproxEqAbs(cumulativeReserves[1].div(ABDKMathQuad.fromUInt(24)).pow_2().toUInt(), 1_807_203, 1); // = 2^((log2(1224743) * 12 + log2(1000000) * 12) / (12 + 12))
    }
}
