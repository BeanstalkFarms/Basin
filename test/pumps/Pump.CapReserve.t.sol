// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TestHelper, console} from "test/TestHelper.sol";
import {MultiFlowPump, ABDKMathQuad} from "src/pumps/MultiFlowPump.sol";
import {simCapReserve50Percent, from18, to18} from "test/pumps/PumpHelpers.sol";
import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";

contract CapBalanceTest is TestHelper, MultiFlowPump {
    using ABDKMathQuad for bytes16;

    constructor()
        MultiFlowPump(
            from18(0.5e18), // cap reserves if changed +/- 50% per block
            from18(0.5e18), // cap reserves if changed +/- 50% per block
            12, // EVM block time
            from18(0.9994445987e18) // geometric EMA constant
        )
    {}

    ////////// Cap: Increase

    function testFuzz_capReserve_capped0BlockIncrease(uint256 last, uint256 curr) public {
        // ensure that curr is greater than 2*last to simulate >= 100% increase
        last = bound(last, 0, type(uint256).max / 2);
        curr = bound(curr, last * 2, type(uint256).max);

        uint256 balance = ABDKMathQuad.toUInt(
            _capReserve(ABDKMathQuad.fromUIntToLog2(last), ABDKMathQuad.fromUIntToLog2(curr), ABDKMathQuad.fromUInt(0))
                .pow_2()
        );

        if (last < 1e24) {
            assertApproxEqAbs(balance, last, 1);
        } else {
            assertApproxEqRel(balance, last, 1);
        }
    }

    function testFuzz_capReserve_xBlocks(uint256 lastBalance, uint256 balance, uint256 blocks) public {
        // ensure that curr is greater than 2*last to simulate >= 100% increase
        // TODO: Potentially relax assumption. Going too high causes arithmetic overflow.
        lastBalance = bound(lastBalance, 100, type(uint128).max);
        balance = bound(balance, 100, type(uint128).max);
        blocks = bound(blocks, 1, 2 ** 12);

        // Add precision for the capReserve function
        uint256 expectedCappedBalance = simCapReserve50Percent(lastBalance, balance, blocks);

        console.log("Expected capped balance", expectedCappedBalance);

        uint256 cappedBalance = _capReserve(
            ABDKMathQuad.fromUIntToLog2(lastBalance),
            ABDKMathQuad.fromUIntToLog2(balance),
            ABDKMathQuad.fromUInt(blocks)
        ).pow_2ToUInt();

        if (cappedBalance < 1e22) {
            assertApproxEqAbs(cappedBalance, expectedCappedBalance, 1);
        } else {
            assertApproxEqRelN(cappedBalance, expectedCappedBalance, 1, 22);
        }
    }

    function test_capReserve_capped1BlockIncrease() public {
        uint256 balance = ABDKMathQuad.toUInt(
            // 1e16 -> 200e16 over 1 block is more than +/- 50%
            // First block:     1  * (1 + 50%) = 1.5     [e16]
            _capReserve(
                ABDKMathQuad.fromUInt(1e16).log_2(), ABDKMathQuad.fromUInt(200e16).log_2(), ABDKMathQuad.fromUInt(1)
            ).pow_2()
        );
        assertApproxEqAbs(balance, 1.5e16, 1);
    }

    function test_capReserve_uncapped2BlockIncrease() public {
        uint256 balance = ABDKMathQuad.toUInt(
            // 1e16 -> 1.2e16 over 2 blocks is within +/- 50%
            _capReserve(
                ABDKMathQuad.fromUInt(1e16).log_2(), ABDKMathQuad.fromUInt(1.2e16).log_2(), ABDKMathQuad.fromUInt(2)
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
                ABDKMathQuad.fromUInt(1e16).log_2(), ABDKMathQuad.fromUInt(200e16).log_2(), ABDKMathQuad.fromUInt(2)
            ).pow_2()
        );
        assertApproxEqAbs(balance, 2.25e16, 1);
    }

    ////////// Cap: Decrease

    function test_capReserve_capped1BlockDecrease() public {
        uint256 balance = ABDKMathQuad.toUInt(
            // 1e16 -> 0.000002e16 over 1 block is more than +/- 50%
            _capReserve(
                ABDKMathQuad.fromUInt(1e16).log_2(), ABDKMathQuad.fromUInt(2e10).log_2(), ABDKMathQuad.fromUInt(1)
            ).pow_2()
        );
        assertApproxEqAbs(balance, 0.5e16, 1);
    }

    function test_capReserve_uncapped1BlockDecrease() public {
        uint256 balance = ABDKMathQuad.toUInt(
            // 1e16 -> 0.75e16 over 1 block is within +/- 50%
            _capReserve(
                ABDKMathQuad.fromUInt(1e16).log_2(), ABDKMathQuad.fromUInt(0.75e16).log_2(), ABDKMathQuad.fromUInt(1)
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
                ABDKMathQuad.fromUInt(1e16).log_2(), ABDKMathQuad.fromUInt(2e10).log_2(), ABDKMathQuad.fromUInt(2)
            ).pow_2()
        );
        assertApproxEqAbs(balance, 0.25e16, 1);
    }

    ////////// Cap: Simulate

    struct CapReservePoint {
        uint256 j;
        uint256 prev;
        uint256 curr;
        uint256 capped;
    }

    function testSim_capReserve_increase() public {
        _simulate(1e16, 200e16, 16, "capReserve_increase");
    }

    function testSim_capReserve_decrease() public {
        _simulate(1e16, 2e10, 32, "capReserve_decrease");
    }

    function _simulate(uint256 prev, uint256 curr, uint256 n, string memory name) internal {
        CapReservePoint[] memory pts = new CapReservePoint[](n);
        uint256 capped = prev;
        for (uint256 j = 1; j <= n; ++j) {
            capped = ABDKMathQuad.toUInt(
                _capReserve(
                    ABDKMathQuad.fromUInt(prev).log_2(), ABDKMathQuad.fromUInt(curr).log_2(), ABDKMathQuad.fromUInt(j)
                ).pow_2()
            );
            pts[j - 1] = CapReservePoint(j, prev, curr, capped);
        }
        _save(name, abi.encode(pts));
    }

    function _save(string memory f, bytes memory s) internal {
        string[] memory inputs = new string[](6);
        inputs[0] = "python3";
        inputs[1] = "test/pumps/simulate.py";
        inputs[2] = "--data";
        inputs[3] = _bytesToHexString(s);
        inputs[4] = "--name";
        inputs[5] = f;
        vm.ffi(inputs);
    }

    function _bytesToHexString(bytes memory buffer) public pure returns (string memory) {
        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);
        bytes memory _base = "0123456789abcdef";
        for (uint256 i; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }
        return string(abi.encodePacked("0x", converted));
    }
}
