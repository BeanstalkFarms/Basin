/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";
import "src/pumps/GeoEmaAndCumSmaPump.sol";

import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";

contract CapBalanceTest is TestHelper, GeoEmaAndCumSmaPump {

    constructor() GeoEmaAndCumSmaPump(0.5e18, 12, 0.9994445987e18) {}

    function test1BlockCapBalanceIncrease() public {
        uint balance = exp2FromUD60x18(capReserve(log2ToUD60x18(1e16), log2ToUD60x18(2e18), 1));
        assertEq(balance, 1.5e16);
    }

    function test2BlockNoCapBalanceIncrease() public {
        uint balance = exp2FromUD60x18(capReserve(log2ToUD60x18(1e16), log2ToUD60x18(1.2e16), 2));
        assertEq(balance, 1.2e16);
    }

    function test2BlockCapBalanceIncrease() public {
        uint balance = exp2FromUD60x18(capReserve(log2ToUD60x18(1e16), log2ToUD60x18(2e18), 2));
        assertEq(balance, 2.25e16);
    }

    function test1BlockCapBalanceDecrease() public {
        uint balance = exp2FromUD60x18(capReserve(log2ToUD60x18(1e16), log2ToUD60x18(2e10), 1));
        assertEq(balance, 0.5e16);
    }

    function test1BlockNoCapBalanceDecrease() public {
        uint balance = exp2FromUD60x18(capReserve(log2ToUD60x18(1e16), log2ToUD60x18(0.75e16), 1));
        assertEq(balance, 0.75e16);
    }

    function test2BlockCapBalanceDecrease() public {
        uint balance = exp2FromUD60x18(capReserve(log2ToUD60x18(1e16), log2ToUD60x18(2e10), 2));
        assertEq(balance, 0.25e16);
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
