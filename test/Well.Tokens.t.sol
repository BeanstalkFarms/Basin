// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Well, IERC20} from "test/TestHelper.sol";

contract WellInternalTest is Well, Test {
    IERC20[] _tokens;
    IERC20 token0;
    IERC20 token1;
    IERC20 tokenMissing1;
    IERC20 tokenMissing2;

    function setUp() public {
        token0 = IERC20(address(1));
        token1 = IERC20(address(2));
        tokenMissing1 = IERC20(address(bytes20("not in well")));
        tokenMissing2 = IERC20(address(bytes20("also not in well")));

        _tokens = new IERC20[](2);
        _tokens[0] = IERC20(token0);
        _tokens[1] = IERC20(token1);
    }

    function test_getIJ() public {
        (uint256 i, uint256 j) = _getIJ(_tokens, token0, token1);
        assertEq(i, 0);
        assertEq(j, 1);

        (i, j) = _getIJ(_tokens, token1, token0);
        assertEq(i, 1);
        assertEq(j, 0);
    }

    function testFuzz_getIJ(uint256 n) public {
        n = bound(n, 2, 16);

        _tokens = new IERC20[](n);
        for (uint256 i = 1; i <= n; ++i) {
            _tokens[i - 1] = IERC20(address(uint160(i)));
        }

        // Check all combinations of tokens
        for (uint256 i; i < n; ++i) {
            for (uint256 j; j < n; ++j) {
                if (i == j) {
                    vm.expectRevert(InvalidTokens.selector);
                }
                (uint256 i_, uint256 j_) = _getIJ(_tokens, _tokens[i], _tokens[j]);
                if (i != j) {
                    assertEq(i_, i, "i");
                    assertEq(j_, j, "j");
                }
            }
        }
    }

    function test_getIJ_revertIfIdentical() public {
        vm.expectRevert(InvalidTokens.selector);
        _getIJ(_tokens, token0, token0);
    }

    function test_getIJ_revertIfOneMissing() public {
        vm.expectRevert(InvalidTokens.selector);
        _getIJ(_tokens, tokenMissing1, token0); // i is missing

        vm.expectRevert(InvalidTokens.selector);
        _getIJ(_tokens, token0, tokenMissing1); // j is missing
    }

    function test_getIJ_revertIfBothMissing() public {
        vm.expectRevert(InvalidTokens.selector);
        _getIJ(_tokens, tokenMissing1, tokenMissing2);
    }

    function test_getJ() public {
        uint256 i = _getJ(_tokens, token0);
        assertEq(i, 0);

        uint256 j = _getJ(_tokens, token1);
        assertEq(j, 1);
    }

    function test_getJ_revertIfMissing() public {
        vm.expectRevert(InvalidTokens.selector);
        _getJ(_tokens, tokenMissing1);
    }
}
