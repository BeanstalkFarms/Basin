/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";
import "src/libraries/LibMath.sol";

contract LibMathTest is TestHelper {
    function setUp() public {}

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