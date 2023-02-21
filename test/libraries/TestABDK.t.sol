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
        bytes16 pu = powuFraction(11_661, 64, 9654);
        assertEq(pu, ABDKMathQuad.from128x128(57_627_117_634_665_864_530_030_077_974_524_244_518_281_427));
    }

    function testFuzz_powu(uint16 num, uint16 denom, uint16 exp) public {
        vm.assume(num < denom);
        vm.assume(denom > 0);
        vm.assume(num > 0);

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
        bytes16 pypu = ABDKMathQuad.from128x128(abi.decode(result, (int)));
        assertEq(pu >> 1, pypu >> 1);
    }

    /// @dev calculate (a/b)^c
    function powuFraction(uint a, uint b, uint c) public pure returns (bytes16) {
        return a.fromUInt().div(b.fromUInt()).powu(c);
    }

    function testFromUIntToLog2() public {
        // test the fromUintToLog2 function

        bytes16 result;

        result = ABDKMathQuad.fromUIntToLog2(0);
        assertEq(result, bytes16(0), "fromUIntToLog2(0) should return 0");

        result = ABDKMathQuad.fromUIntToLog2(1);
        assertEq(result, bytes16(0x3FFE0000000000000000000000000000), "fromUIntToLog2(1) should return 0x3FFE0000000000000000000000000000");

        result = ABDKMathQuad.fromUIntToLog2(2);
        assertEq(result, bytes16(0x3FFF0000000000000000000000000000), "fromUIntToLog2(2) should return 0x3FFF0000000000000000000000000000");

        // assertEq(ABDKMathQuad.fromUIntToLog2(1), 0);

    }
}
