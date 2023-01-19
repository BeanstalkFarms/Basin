/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";
import "src/libraries/LibMath.sol";

contract LibMathTest is TestHelper {
    // Wells permit up to  16 tokens. Currently, `nthRoot` is only used
    // with `a = balances.length` which is constrained to `2 <= a <= 16`.
    uint MAX_NTH_ROOT = 16;

    function setUp() public {}

    //////////// NTH ROOT ////////////
    
    /// @dev check requirements

    /// @dev zero cases for all 
    function test_nthRoot_zero() public {
        for (uint n = 2; n <= MAX_NTH_ROOT; ++n) {
            assertEq(LibMath.nthRoot(0, n), 0);
        }
    }
    
    /// @dev verify exact match of LibMath.sqrt when n == 2
    function test_nthRoot_sqrtMatch() public {
        assertEq(LibMath.nthRoot(4, 2), LibMath.sqrt(4));
    }

    function testFuzz_nthRoot_sqrtMatch(uint a) public {
        vm.assume(a < type(uint256).max);
        assertEq(LibMath.nthRoot(a, 2), LibMath.sqrt(a));
    }

    /// @dev for all even roots, nthRoot exactly matches `n` sqrt iterations
    function testFuzz_nthRoot_sqrtMatchAll(uint a) public {
        // every even nth root: 2 4 6 8 10 12 14 16
        for(uint i = 2; i < MAX_NTH_ROOT; i += 2) {
            uint v = a;
            // run sqrt up to i/2 times
            for (uint j = 0; j < i/2; ++j) {
                v = LibMath.sqrt(v);
            }
            assertEq(LibMath.nthRoot(a, i), v, "nthRoot != nth sqrt");
        }
    }

    //////////// SQRT ////////////

    /// @dev zero case
    function testSqrt0() public {
        assertEq(LibMath.sqrt(0), 0);
    }

    /// @dev perfect square case, small number
    function testSqrtPerfectSmall() public {
        assertEq(LibMath.sqrt(4), 2);
    }

    /// @dev perfect square case, large number
    /// 4e6 = sqrt(1.6e13)
    function testSqrtPerfectLarge() public {
        assertEq(LibMath.sqrt(16 * 1e12), 4 * 1e6);
    }

    /// @dev imperfect square case, small number with decimal < 0.5
    function testSqrtImperfectSmallLt() public {
        assertEq(LibMath.sqrt(2), 1); // rounds down from 1.414...
    }

    /// @dev imperfect square case, large number with decimal < 0.5
    function testSqrtImperfectLargeLt() public {
        assertEq(LibMath.sqrt(1250 * 1e6), 35355); // rounds down from 35355.339...
    }

    /// @dev imperfect square case, small number with decimal >= 0.5
    function testSqrtImperfectSmallGte() public {
        assertEq(LibMath.sqrt(3), 1); // rounds down from 1.732...
    }

    /// @dev imperfect square case, small number with decimal >= 0.5
    /// 2828427124 = sqrt(8e18)
    function testSqrtImperfectLargeGte() public {
        assertEq(LibMath.sqrt(8 * 1e18), 2828427124); // rounds down from 2.828...e9
    }
}