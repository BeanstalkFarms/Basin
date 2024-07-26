// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "test/TestHelper.sol";
import "src/libraries/ABDKMathQuad.sol";
import "oz/utils/Strings.sol";

contract ABDKTest is TestHelper {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;
    using Strings for uint256;

    int256 constant uUINT128 = 2 ** 128;

    //////////////////// CORE ////////////////////

    /**
     * @dev no hysteresis: 2^(log2(a)) == a +/- 1 (due to library rounding)
     */
    function testFuzz_log2Pow2(uint256 a) public {
        a = bound(a, 1, type(uint256).max);
        uint256 b = (a.fromUInt().log_2()).pow_2().toUInt();
        if (a <= 1e18) {
            assertApproxEqAbs(a, b, 1);
        } else {
            assertApproxEqRel(a, b, 1);
        }
    }

    //////////////////// EXTENSIONS ////////////////////

    function test_powu1() public {
        bytes16 pu = powuFraction(9, 10, 10);
        uint256 puu = uint256(pu.to128x128());
        uint256 expected = 118_649_124_891_528_663_468_500_301_601_258_807_155;
        assertApproxEqRelN(puu, expected, 1, 32);
    }

    function testFuzz_powu(uint256 num, uint256 denom, uint256 exp) public {
        denom = bound(denom, 1, type(uint16).max);
        num = bound(num, 1, denom);

        string[] memory inputs = new string[](8);
        inputs[0] = "python";
        inputs[1] = "test/differential/powu.py";
        inputs[2] = "--numerator";
        inputs[3] = uint256(num).toString();
        inputs[4] = "--denominator";
        inputs[5] = uint256(denom).toString();
        inputs[6] = "--exponent";
        inputs[7] = uint256(exp).toString();
        bytes memory result = vm.ffi(inputs);

        bytes16 pu = powuFraction(num, denom, exp);
        uint256 puu = uint256(pu.to128x128());
        uint256 pypu = uint256(abi.decode(result, (int256)));

        // Rounding error starts at 5e27
        if (puu > 5e27) {
            assertApproxEqRelN(puu, pypu, 2, 28); // expecting precision to 2e-28
        } else {
            assertApproxEqAbs(puu, pypu, 1);
        }
    }

    /// @dev calculate (a/b)^c
    function powuFraction(uint256 a, uint256 b, uint256 c) public pure returns (bytes16) {
        return a.fromUInt().div(b.fromUInt()).powu(c);
    }

    function testFuzz_FromUIntToLog2(uint256 x) public pure {
        x = bound(x, 1, type(uint256).max);
        assertEq(ABDKMathQuad.fromUInt(x).log_2(), ABDKMathQuad.fromUIntToLog2(x));
    }

    function testFuzz_pow_2ToUInt(uint256 x) public pure {
        x = bound(x, 0, 255);

        // test the pow_2ToUInt function
        bytes16 _x = x.fromUInt();
        assertEq(ABDKMathQuad.pow_2(_x).toUInt(), ABDKMathQuad.pow_2ToUInt(_x));
    }
}
