// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console, TestHelper, IERC20} from "test/TestHelper.sol";
import {CurveStableSwap2} from "src/functions/CurveStableSwap2.sol";
import {IBeanstalkWellFunction} from "src/interfaces/IBeanstalkWellFunction.sol";

/// @dev Tests the {ConstantProduct2} Well function directly.
contract CurveStableSwap2LiquidityTest is TestHelper {
    IBeanstalkWellFunction _f;
    bytes data;

    //////////// SETUP ////////////

    function setUp() public {
        _f = new CurveStableSwap2(address(1));
        deployMockTokens(2);
        data = abi.encode(18, 18);
    }

    function test_calcReserveAtRatioLiquidity_equal_equal() public view {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 100;
        reserves[1] = 100;
        uint256[] memory ratios = new uint256[](2);
        ratios[0] = 1;
        ratios[1] = 1;

        uint256 reserve0 = _f.calcReserveAtRatioLiquidity(reserves, 0, ratios, data);
        uint256 reserve1 = _f.calcReserveAtRatioLiquidity(reserves, 1, ratios, data);

        assertEq(reserve0, 100);
        assertEq(reserve1, 100);
    }

    function test_calcReserveAtRatioLiquidity_equal_diff() public view {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 50;
        reserves[1] = 100;
        uint256[] memory ratios = new uint256[](2);
        ratios[0] = 1;
        ratios[1] = 1;

        uint256 reserve0 = _f.calcReserveAtRatioLiquidity(reserves, 0, ratios, data);
        uint256 reserve1 = _f.calcReserveAtRatioLiquidity(reserves, 1, ratios, data);

        assertEq(reserve0, 100);
        assertEq(reserve1, 50);
    }

    function test_calcReserveAtRatioLiquidity_diff_equal() public view {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 100;
        reserves[1] = 100;
        uint256[] memory ratios = new uint256[](2);
        ratios[0] = 2;
        ratios[1] = 1;

        uint256 reserve0 = _f.calcReserveAtRatioLiquidity(reserves, 0, ratios, data);
        uint256 reserve1 = _f.calcReserveAtRatioLiquidity(reserves, 1, ratios, data);

        assertEq(reserve0, 200);
        assertEq(reserve1, 50);
    }

    function test_calcReserveAtRatioLiquidity_diff_diff() public view {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 50;
        reserves[1] = 100;
        uint256[] memory ratios = new uint256[](2);
        ratios[0] = 2;
        ratios[1] = 1;

        uint256 reserve0 = _f.calcReserveAtRatioLiquidity(reserves, 0, ratios, data);
        uint256 reserve1 = _f.calcReserveAtRatioLiquidity(reserves, 1, ratios, data);

        assertEq(reserve0, 200);
        assertEq(reserve1, 25);
    }

    function test_calcReserveAtRatioLiquidity_fuzz(uint256[2] memory reserves, uint256[2] memory ratios) public {
        for (uint256 i; i < 2; ++i) {
            // Upper bound is limited by stableSwap,
            // due to the stableswap reserves being extremely far apart.
            reserves[i] = bound(reserves[i], 1e18, 1e31);
            ratios[i] = bound(ratios[i], 1e6, 1e18);
        }

        uint256 lpTokenSupply = _f.calcLpTokenSupply(uint2ToUintN(reserves), data);
        console.log(lpTokenSupply);

        uint256[] memory reservesOut = new uint256[](2);
        for (uint256 i; i < 2; ++i) {
            reservesOut[i] = _f.calcReserveAtRatioLiquidity(uint2ToUintN(reserves), i, uint2ToUintN(ratios), data);
        }

        // Precision is set to the minimum number of digits of the reserves out.
        uint256 precision = numDigits(reservesOut[0]) > numDigits(reservesOut[1])
            ? numDigits(reservesOut[1])
            : numDigits(reservesOut[0]);

        // Check ratio of each `reserveOut` to `reserve` with the ratio of `ratios`.
        // If inequality doesn't hold, then reserves[1] will be zero
        if (ratios[0] * reserves[1] >= ratios[1]) {
            assertApproxEqRelN(reservesOut[0] * ratios[1], ratios[0] * reserves[1], 1, precision);
        } else {
            // Because `roundedDiv` is used. It could round up to 1.
            assertApproxEqAbs(reservesOut[0], 0, 1, "reservesOut[0] should be zero");
        }

        // If inequality doesn't hold, then reserves[1] will be zero
        if (reserves[0] * ratios[1] >= ratios[0]) {
            assertApproxEqRelN(reserves[0] * ratios[1], ratios[0] * reservesOut[1], 1, precision);
        } else {
            // Because `roundedDiv` is used. It could round up to 1.
            assertApproxEqAbs(reservesOut[1], 0, 1, "reservesOut[1] should be zero");
        }
    }

    function test_calcReserveAtRatioLiquidity_invalidJ() public {
        uint256[] memory reserves = new uint256[](2);
        uint256[] memory ratios = new uint256[](2);
        vm.expectRevert();
        _f.calcReserveAtRatioLiquidity(reserves, 2, ratios, "");
    }
}
