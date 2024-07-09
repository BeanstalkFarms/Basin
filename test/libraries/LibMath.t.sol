// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TestHelper} from "test/TestHelper.sol";
import {LibMath} from "src/libraries/LibMath.sol";

contract LibMathTest is TestHelper {
    // Wells permit up to  16 tokens. Currently, `nthRoot` is only used
    // with `a = reserves.length` which is constrained to `2 <= a <= 16`.
    uint256 MAX_NTH_ROOT = 16;

    function setUp() public {}

    //////////// NTH ROOT ////////////

    /// @dev check requirements

    /// @dev zero cases for all
    function test_nthRoot_zero() public {
        for (uint256 n = 2; n <= MAX_NTH_ROOT; ++n) {
            assertEq(LibMath.nthRoot(0, n), 0);
        }
    }

    /// @dev verify exact match of LibMath.sqrt when n == 2
    function test_nthRoot_sqrtMatch() public {
        assertEq(LibMath.nthRoot(4, 2), LibMath.sqrt(4));
    }

    function testFuzz_nthRoot_sqrtMatch(uint256 a) public {
        vm.assume(a < type(uint256).max);
        assertEq(LibMath.nthRoot(a, 2), LibMath.sqrt(a));
    }

    /// @dev for all even roots, nthRoot exactly matches `n` sqrt iterations
    function testFuzz_nthRoot_sqrtMatchAll(uint256 a) public {
        // every even nth root: 2 4 8 16
        for (uint256 i = 1; i <= 4; ++i) {
            uint256 v = a;
            for (uint256 j; j < i; ++j) {
                v = LibMath.sqrt(v);
            }
            assertEq(LibMath.nthRoot(a, 2 ** i), v, "nthRoot != nth sqrt");
        }
    }

    //////////// SQRT ////////////

    /// @dev zero case
    function testSqrt0() public pure {
        assertEq(LibMath.sqrt(0), 0);
    }

    /// @dev perfect square case, small number
    function testSqrtPerfectSmall() public pure {
        assertEq(LibMath.sqrt(4), 2);
    }

    /// @dev perfect square case, large number
    /// 4e6 = sqrt(1.6e13)
    function testSqrtPerfectLarge() public pure {
        assertEq(LibMath.sqrt(16 * 1e12), 4 * 1e6);
    }

    /// @dev imperfect square case, small number with decimal < 0.5
    function testSqrtImperfectSmallLt() public pure {
        assertEq(LibMath.sqrt(2), 1); // rounds down from 1.414...
    }

    /// @dev imperfect square case, large number with decimal < 0.5
    function testSqrtImperfectLargeLt() public pure {
        assertEq(LibMath.sqrt(1250 * 1e6), 35_355); // rounds down from 35355.339...
    }

    /// @dev imperfect square case, small number with decimal >= 0.5
    function testSqrtImperfectSmallGte() public pure {
        assertEq(LibMath.sqrt(3), 1); // rounds down from 1.732...
    }

    /// @dev imperfect square case, small number with decimal >= 0.5
    /// 2828427124 = sqrt(8e18)
    function testSqrtImperfectLargeGte() public pure {
        assertEq(LibMath.sqrt(8 * 1e18), 2_828_427_124); // rounds down from 2.828...e9
    }

    ///
    function test_roundUpDiv_revertIf_denomIsZero() public {
        vm.expectRevert();
        LibMath.roundUpDiv(1, 0);
    }

    function test_roundUpDiv() public pure {
        assertEq(LibMath.roundUpDiv(1, 3), 1);
        assertEq(LibMath.roundUpDiv(1, 2), 1);
        assertEq(LibMath.roundUpDiv(2, 3), 1);
        assertEq(LibMath.roundUpDiv(2, 2), 1);
        assertEq(LibMath.roundUpDiv(3, 2), 2);
        assertEq(LibMath.roundUpDiv(5, 4), 2);
    }

    function test_fuzz_roundUpDiv(uint256 a, uint256 b) public {
        if (a > 0 && b == 0) {
            vm.expectRevert();
            LibMath.roundUpDiv(a, b);
            return;
        }

        uint256 c = LibMath.roundUpDiv(a, b);

        if (a == 0) {
            assertEq(c, 0);
            return;
        }

        uint256 a_guess;
        unchecked {
            a_guess = c * b;
        }
        if (a_guess == a) {
            assertEq(c, a / b);
        } else {
            assertEq(c, a / b + 1);
        }
    }
}
