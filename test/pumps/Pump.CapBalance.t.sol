// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "test/TestHelper.sol";
import "src/pumps/GeoEmaAndCumSmaPump.sol";
import {from18, to18} from "utils/PumpEncoder.sol";

import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";

contract CapBalanceTest is TestHelper, GeoEmaAndCumSmaPump {

    using ABDKMathQuad for bytes16;

    constructor()
        GeoEmaAndCumSmaPump(from18(0.5e18), 12, from18(0.9994445987e18))
    {}

    function test1BlockCapBalanceIncrease() public {
        uint256 balance = ABDKMathQuad.toUInt(
            capReserve(
                ABDKMathQuad.fromUInt(1e16).log_2(),
                ABDKMathQuad.fromUInt(2e18).log_2(),
                ABDKMathQuad.fromUInt(1)
            ).pow_2()
        );
        assertApproxEqAbs(balance, 1.5e16, 1);
    }

    function test2BlockNoCapBalanceIncrease() public {
        uint256 balance = ABDKMathQuad.toUInt(
            capReserve(
                ABDKMathQuad.fromUInt(1e16).log_2(),
                ABDKMathQuad.fromUInt(1.2e16).log_2(),
                ABDKMathQuad.fromUInt(2)
            ).pow_2()
        );
        assertApproxEqAbs(balance, 1.2e16, 1);
    }

    function test2BlockCapBalanceIncrease() public {
        uint256 balance = ABDKMathQuad.toUInt(
            capReserve(
                ABDKMathQuad.fromUInt(1e16).log_2(),
                ABDKMathQuad.fromUInt(2e18).log_2(),
                ABDKMathQuad.fromUInt(2)
            ).pow_2()
        );
        assertApproxEqAbs(balance, 2.25e16, 1);
    }

    function test1BlockCapBalanceDecrease() public {
        uint256 balance = ABDKMathQuad.toUInt(
            capReserve(
                ABDKMathQuad.fromUInt(1e16).log_2(),
                ABDKMathQuad.fromUInt(2e10).log_2(),
                ABDKMathQuad.fromUInt(1)
            ).pow_2()
        );
        assertApproxEqAbs(balance, 0.5e16, 1);
    }

    function test1BlockNoCapBalanceDecrease() public {
        uint256 balance = ABDKMathQuad.toUInt(
            capReserve(
                ABDKMathQuad.fromUInt(1e16).log_2(),
                ABDKMathQuad.fromUInt(0.75e16).log_2(),
                ABDKMathQuad.fromUInt(1)
            ).pow_2()
        );
        assertApproxEqAbs(balance, 0.75e16, 1);
    }

    function test2BlockCapBalanceDecrease() public {
        uint256 balance = ABDKMathQuad.toUInt(
            capReserve(
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
