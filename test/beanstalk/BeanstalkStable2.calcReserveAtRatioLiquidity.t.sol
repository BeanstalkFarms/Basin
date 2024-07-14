// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console, TestHelper, IERC20} from "test/TestHelper.sol";
import {Stable2} from "src/functions/Stable2.sol";
import {IBeanstalkWellFunction} from "src/interfaces/IBeanstalkWellFunction.sol";
import {Stable2LUT1} from "src/functions/StableLUT/Stable2LUT1.sol";

/// @dev Tests the {Stable2.CalcReserveAtRatioLiquidity} Well function directly.
contract BeanstalkStable2LiquidityTest is TestHelper {
    IBeanstalkWellFunction _f;
    bytes data;

    //////////// SETUP ////////////

    function setUp() public {
        address lut = address(new Stable2LUT1());
        _f = new Stable2(lut);
        deployMockTokens(2);
        data = abi.encode(18, 18);
    }

    function test_calcReserveAtRatioLiquidity_equal_equal() public view {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 100e18;
        reserves[1] = 100e18;
        uint256[] memory ratios = new uint256[](2);
        ratios[0] = 1;
        ratios[1] = 1;

        uint256 reserve0 = _f.calcReserveAtRatioLiquidity(reserves, 0, ratios, data);
        uint256 reserve1 = _f.calcReserveAtRatioLiquidity(reserves, 1, ratios, data);

        assertEq(reserve0, 99.997220935618347533e18);
        assertEq(reserve1, 99.997220935618347533e18);
    }

    function test_calcReserveAtRatioLiquidity_equal_diff() public view {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 50e18;
        reserves[1] = 100e18;
        uint256[] memory ratios = new uint256[](2);
        ratios[0] = 1;
        ratios[1] = 1;

        uint256 reserve0 = _f.calcReserveAtRatioLiquidity(reserves, 0, ratios, data);
        uint256 reserve1 = _f.calcReserveAtRatioLiquidity(reserves, 1, ratios, data);

        assertEq(reserve0, 99.997220935618347533e18);
        assertEq(reserve1, 49.998610467809173766e18);
    }

    function test_calcReserveAtRatioLiquidity_diff_equal() public view {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 1e18;
        reserves[1] = 1e18;
        uint256[] memory ratios = new uint256[](2);
        ratios[0] = 2;
        ratios[1] = 1;

        uint256 reserve0 = _f.calcReserveAtRatioLiquidity(reserves, 0, ratios, data);
        uint256 reserve1 = _f.calcReserveAtRatioLiquidity(reserves, 1, ratios, data);

        assertEq(reserve0, 4.576172337359416271e18);
        assertEq(reserve1, 0.218464636709548541e18);
    }

    function test_calcReserveAtRatioLiquidity_diff_diff() public view {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 2e18;
        reserves[1] = 1e18;
        uint256[] memory ratios = new uint256[](2);
        ratios[0] = 12;
        ratios[1] = 10;
        // p = 1.2

        uint256 reserve0 = _f.calcReserveAtRatioLiquidity(reserves, 0, ratios, data);
        uint256 reserve1 = _f.calcReserveAtRatioLiquidity(reserves, 1, ratios, data);

        assertEq(reserve0, 1.685434381143450467e18);
        assertEq(reserve1, 0.593220305288953143e18);
    }

    function test_calcReserveAtRatioLiquidity_fuzz(uint256[2] memory reserves, uint256[2] memory ratios) public view {
        for (uint256 i; i < 2; ++i) {
            // Upper bound is limited by stableSwap,
            // due to the stableswap reserves being extremely far apart.
            reserves[i] = bound(reserves[i], 1e18, 1e31);
            ratios[i] = bound(ratios[i], 1e18, 4e18);
        }

        // create 2 new reserves, one where reserve[0] is updated, and one where reserve[1] is updated.
        uint256[] memory r0Updated = new uint256[](2);
        r0Updated[1] = reserves[1];
        uint256[] memory r1Updated = new uint256[](2);
        r1Updated[0] = reserves[0];
        for (uint256 i; i < 2; ++i) {
            uint256 reserve = _f.calcReserveAtRatioLiquidity(uint2ToUintN(reserves), i, uint2ToUintN(ratios), data);
            // update reserves.
            if (i == 0) {
                r0Updated[0] = reserve;
            } else {
                r1Updated[1] = reserve;
            }
        }

        {
            uint256 targetPrice = ratios[0] * 1e6 / ratios[1];
            uint256 reservePrice0 = _f.calcRate(r0Updated, 0, 1, data);
            uint256 reservePrice1 = _f.calcRate(r1Updated, 0, 1, data);

            uint256 targetPriceInverted = ratios[1] * 1e6 / ratios[0];
            uint256 reservePrice0Inverted = _f.calcRate(r0Updated, 1, 0, data);
            uint256 reservePrice1Inverted = _f.calcRate(r1Updated, 1, 0, data);

            // estimated price and actual price are within 0.04% in the worst case.
            assertApproxEqRel(targetPrice, reservePrice0, 0.0004e18, "targetPrice <> reservePrice0");
            assertApproxEqRel(targetPrice, reservePrice1, 0.0004e18, "targetPrice <> reservePrice1");
            assertApproxEqRel(reservePrice0, reservePrice1, 0.0004e18, "reservePrice0 <> reservePrice1");
        }
    }

    function test_calcReserveAtRatioLiquidity_invalidJ() public {
        uint256[] memory reserves = new uint256[](2);
        uint256[] memory ratios = new uint256[](2);
        vm.expectRevert();
        _f.calcReserveAtRatioLiquidity(reserves, 2, ratios, "");
    }
}
