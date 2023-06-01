pragma solidity ^0.8.17;

import "test/TestHelper.sol";
import "src/libraries/ABDKMathQuad.sol";
import "oz/utils/Strings.sol";

contract ABDKTest is TestHelper {
    using ABDKMathQuad for uint;
    using ABDKMathQuad for bytes16;
    using Strings for uint;

    int constant uUINT128 = 2 ** 128;

    //////////////////// CORE ////////////////////

    /**
     * @dev no hysteresis: 2^(log2(a)) == a +/- 1 (due to library rounding)
     */
    function testFuzz_log2Pow2(uint a) public {
        vm.assume(a > 0);
        uint b = (a.fromUInt().log_2()).pow_2().toUInt();
        if (a <= 1e18) {
            assertApproxEqAbs(a, b, 1);
        } else {
            assertApproxEqRel(a, b, 1);
        }
    }

    //////////////////// EXTENSIONS ////////////////////

    function test_powu1() public {
        bytes16 pu = powuFraction(9, 10, 10);
        uint puu = uint(pu.to128x128());
        uint expected = 118_649_124_891_528_663_468_500_301_601_258_807_155;
        assertApproxEqRelN(puu, expected, 1, 32);
    }

    function testFuzz_powu(uint num, uint denom, uint exp) public {
        denom = bound(denom, 1, type(uint16).max);
        num = bound(num, 1, denom);

        string[] memory inputs = new string[](8);
        inputs[0] = "python";
        inputs[1] = "test/differential/powu.py";
        inputs[2] = "--numerator";
        inputs[3] = uint(num).toString();
        inputs[4] = "--denominator";
        inputs[5] = uint(denom).toString();
        inputs[6] = "--exponent";
        inputs[7] = uint(exp).toString();
        bytes memory result = vm.ffi(inputs);

        bytes16 pu = powuFraction(num, denom, exp);
        uint puu = uint(pu.to128x128());
        uint pypu = uint(abi.decode(result, (int)));

        // Rounding error starts at 5e27
        if (puu > 5e27) {
            assertApproxEqRelN(puu, pypu, 2, 28); // expecting precision to 2e-28
        } else {
            assertApproxEqAbs(puu, pypu, 1);
        }
    }

    /// @dev calculate (a/b)^c
    function powuFraction(uint a, uint b, uint c) public pure returns (bytes16) {
        return a.fromUInt().div(b.fromUInt()).powu(c);
    }

    function testFuzz_FromUIntToLog2(uint x) public {
        vm.assume(x > 0); // log2(0) is undefined.
        assertEq(ABDKMathQuad.fromUInt(x).log_2(), ABDKMathQuad.fromUIntToLog2(x));
    }

    function testFuzz_pow_2ToUInt(uint x) public {
        vm.assume(x < 256); // the max value of an uint is 2^256 - 1.

        // test the pow_2ToUInt function
        bytes16 _x = x.fromUInt();
        assertEq(ABDKMathQuad.pow_2(_x).toUInt(), ABDKMathQuad.pow_2ToUInt(_x));
    }
}
