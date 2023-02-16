// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "test/TestHelper.sol";
import "src/pumps/GeoEmaAndCumSmaPump.sol";
import {from18, to18} from "test/pumps/PumpHelpers.sol";

import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";

contract PumpUpdateTest is TestHelper {
    using ABDKMathQuad for bytes16;

    GeoEmaAndCumSmaPump pump;
    uint[] b = new uint[](2);

    uint256 constant BLOCK_TIME = 12;

    /// @dev for this test, `user` = a Well that's calling the Pump
    function setUp() public {
        initUser();
        pump = new GeoEmaAndCumSmaPump(
            from18(0.5e18), // max % change in reserves per block is 50%
            12, // block time
            from18(0.9e18) // ema alpha
        );

        // Send first update to the Pump, which will initialize it
        vm.prank(user);
        b[0] = 1e6;
        b[1] = 2e6;
        pump.update(b, new bytes(0));
    }

    function test_initialized() public prank(user) {
        // Last reserves are initialized with initial liquidity
        uint[] memory lastReserves = pump.readLastReserves(user);
        assertApproxEqAbs(lastReserves[0], 1e6, 1);
        assertApproxEqAbs(lastReserves[1], 2e6, 1);

        // EMA reserves are initialized with initial liquidity
        uint[] memory lastEmaReserves = pump.readInstantaneousReserves(user);
        assertApproxEqAbs(lastEmaReserves[0], 1e6, 1);
        assertApproxEqAbs(lastEmaReserves[1], 2e6, 1);

        // Cumulative reserves are initialized to zero
        bytes16[] memory lastCumulativeReserves = pump.readLastCumulativeReserves(user);
        assertEq(lastCumulativeReserves[0], bytes16(0));
        assertEq(lastCumulativeReserves[1], bytes16(0));
    }

    /// @dev no time has elapsed since prev update = no change
    function test_update_0Seconds() public prank(user) {
        b[0] = 2e6;
        b[1] = 1e6;
        pump.update(b, new bytes(0));
        
        uint[] memory lastReserves = pump.readLastReserves(user);
        assertApproxEqAbs(lastReserves[0], 1e6, 1);
        assertApproxEqAbs(lastReserves[1], 2e6, 1);

        uint[] memory lastEmaReserves = pump.readInstantaneousReserves(user);
        assertApproxEqAbs(lastEmaReserves[0], 1e6, 1);
        assertApproxEqAbs(lastEmaReserves[1], 2e6, 1);

        bytes16[] memory lastCumulativeReserves = pump.readLastCumulativeReserves(user);
        assertEq(lastCumulativeReserves[0], bytes16(0));
        assertEq(lastCumulativeReserves[1], bytes16(0));
    }

    function test_update_12Seconds() public prank(user) {
        // After BLOCK_TIME, Pump receives an update
        increaseTime(BLOCK_TIME);
        b[0] = 2e6; // 1e6 -> 2e6 = +100%
        b[1] = 1e6; // 2e6 -> 1e6 = - 50%
        pump.update(b, new bytes(0));

        // 
        uint[] memory lastReserves = pump.readLastReserves(user);
        assertApproxEqAbs(lastReserves[0], 1.5e6, 1);   // capped
        assertApproxEqAbs(lastReserves[1], 1e6, 1);     // uncapped

        // 
        uint[] memory lastEmaReserves = pump.readInstantaneousReserves(user);
        assertEq(lastEmaReserves[0], 1337697); // 1.33e6
        assertEq(lastEmaReserves[1], 1216241); // 1.21e6

        // 
        bytes16[] memory lastCumulativeReserves = pump.readLastCumulativeReserves(user);
        assertApproxEqAbs(lastCumulativeReserves[0].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1.5e6, 1);
        assertApproxEqAbs(lastCumulativeReserves[1].div(ABDKMathQuad.fromUInt(12)).pow_2().toUInt(), 1e6, 1);
    }
}
