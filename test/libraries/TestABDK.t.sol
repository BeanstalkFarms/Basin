import "test/TestHelper.sol";
import "src/libraries/ABDKMathQuad.sol";
import "oz/utils/Strings.sol";

contract ABDKTest is TestHelper {
    using ABDKMathQuad for uint;
    using ABDKMathQuad for bytes16;
    using Strings for uint;

    int constant uUINT128 = 2 ** 128;

    function check(uint a) public view returns (uint b) {
        b = a.fromUInt().log_2().pow_2().toUInt();
    }

    function test_fuzzLog2Pow2(uint a) public {
        vm.assume(a > 0);
        uint b = check(a);
        //160755502
        if (a <= 1e18) {
            assertApproxEqAbs(a, b, 1);
        } else {
            assertApproxEqRel(a, b, 1);
        }
    }

    function powuFraction(uint a, uint b, uint c) public pure returns (bytes16) {
        return a.fromUInt().div(b.fromUInt()).powu(c);
    }

    function testPowu1() public {
        bytes16 pu = powuFraction(11_661, 64, 9654);
        assertEq(pu, ABDKMathQuad.from128x128(57_627_117_634_665_864_530_030_077_974_524_244_518_281_427));
    }

    function test_fuzzPowu(uint16 num, uint16 denom, uint16 exp) public {
        vm.assume(num < denom);
        vm.assume(denom > 0);
        vm.assume(num > 0);

        string[] memory inputs = new string[](8);
        inputs[0] = "python";
        inputs[1] = "test/differential/powu.py";
        inputs[2] = "--numerator";
        inputs[4] = "--denominator";
        inputs[6] = "--exponent";

        inputs[3] = uint(num).toString();
        inputs[5] = uint(denom).toString();
        inputs[7] = uint(exp).toString();
        bytes memory result = vm.ffi(inputs);
        bytes16 pu = powuFraction(num, denom, exp);
        bytes16 pypu = ABDKMathQuad.from128x128(abi.decode(result, (int)));
        assertEq(pu >> 1, pypu >> 1);
    }
}
