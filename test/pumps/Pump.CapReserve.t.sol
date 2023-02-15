// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "test/TestHelper.sol";
import "src/pumps/GeoEmaAndCumSmaPump.sol";
import {from18, to18} from "test/pumps/PumpHelpers.sol";
import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";

contract CapBalanceTest is TestHelper, GeoEmaAndCumSmaPump {
    using ABDKMathQuad for bytes16;

    constructor()
        GeoEmaAndCumSmaPump(
            from18(0.5e18), // cap reserves if changed +/- 50% per block
            12, // EVM block time
            from18(0.9994445987e18) // geometric EMA constant
        )
    {}

    ////////// Cap: Increase

    function test_capReserve_capped1BlockIncrease() public {
        uint256 balance = ABDKMathQuad.toUInt(
            // 1e16 -> 200e16 over 1 block is more than +/- 50%
            // First block:     1  * (1 + 50%) = 1.5     [e16]
            _capReserve(
                ABDKMathQuad.fromUInt(1e16).log_2(),
                ABDKMathQuad.fromUInt(200e16).log_2(),
                ABDKMathQuad.fromUInt(1)
            ).pow_2()
        );
        assertApproxEqAbs(balance, 1.5e16, 1);
    }

    function test_capReserve_uncapped2BlockIncrease() public {
        uint256 balance = ABDKMathQuad.toUInt(
            // 1e16 -> 1.2e16 over 2 blocks is within +/- 50%
            _capReserve(
                ABDKMathQuad.fromUInt(1e16).log_2(),
                ABDKMathQuad.fromUInt(1.2e16).log_2(),
                ABDKMathQuad.fromUInt(2)
            ).pow_2()
        );
        assertApproxEqAbs(balance, 1.2e16, 1);
    }

    function test_capReserve_capped2BlockIncrease() public {
        uint256 balance = ABDKMathQuad.toUInt(
            // 1e16 -> 200e16 over 2 blocks is more than +/- 50%
            // First block:     1   * (1 + 50%) = 1.5    [e16]
            // Second block:    1.5 * (1 + 50%) = 2.25   [e16]
            _capReserve(
                ABDKMathQuad.fromUInt(1e16).log_2(),
                ABDKMathQuad.fromUInt(200e16).log_2(),
                ABDKMathQuad.fromUInt(2)
            ).pow_2()
        );
        assertApproxEqAbs(balance, 2.25e16, 1);
    }

    ////////// Cap: Decrease

    function test_capReserve_capped1BlockDecrease() public {
        uint256 balance = ABDKMathQuad.toUInt(
            // 1e16 -> 0.000002e16 over 1 block is more than +/- 50%
            _capReserve(
                ABDKMathQuad.fromUInt(1e16).log_2(),
                ABDKMathQuad.fromUInt(2e10).log_2(),
                ABDKMathQuad.fromUInt(1)
            ).pow_2()
        );
        assertApproxEqAbs(balance, 0.5e16, 1);
    }

    function test_capReserve_uncapped1BlockDecrease() public {
        uint256 balance = ABDKMathQuad.toUInt(
            // 1e16 -> 0.75e16 over 1 block is within +/- 50%
            _capReserve(
                ABDKMathQuad.fromUInt(1e16).log_2(),
                ABDKMathQuad.fromUInt(0.75e16).log_2(),
                ABDKMathQuad.fromUInt(1)
            ).pow_2()
        );
        assertApproxEqAbs(balance, 0.75e16, 1);
    }

    function test_capReserve_capped2BlockDecrease() public {
        uint256 balance = ABDKMathQuad.toUInt(
            // 1e16 -> 0.000002e16 over 2 blocks is more than +/- 50%
            // First block:     1   * (1 - 50%) = 0.5    [e16]
            // Second block:    0.5 * (1 - 50%) = 0.25   [e16]
            _capReserve(
                ABDKMathQuad.fromUInt(1e16).log_2(),
                ABDKMathQuad.fromUInt(2e10).log_2(),
                ABDKMathQuad.fromUInt(2)
            ).pow_2()
        );
        assertApproxEqAbs(balance, 0.25e16, 1);
    }

    // function testPump2() public {
    //     uint x;
    //     uint y;
    //     uint err;
    //     for (uint i=1; i <= 128; ++i) {
    //         x = 2**i;
    //         y = i * 1e18-1;
    //         err = x-unwrap(exp2(wrap(y)))/1e18;
    //         console.log("i:", i);
    //         console.log(err);
    //         console.log(x);
    //         console.log(err * 1e19/x);
    //     }
    // }
}
