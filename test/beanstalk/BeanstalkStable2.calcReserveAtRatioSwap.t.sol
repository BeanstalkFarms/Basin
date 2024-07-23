// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {console, TestHelper, IERC20} from "test/TestHelper.sol";
import {Stable2} from "src/functions/Stable2.sol";
import {IBeanstalkWellFunction} from "src/interfaces/IBeanstalkWellFunction.sol";
import {Stable2LUT1} from "src/functions/StableLUT/Stable2LUT1.sol";

/// @dev Tests the {Stable2} Well function directly.
contract BeanstalkStable2SwapTest is TestHelper {
    IBeanstalkWellFunction _f;
    bytes data;

    //////////// SETUP ////////////

    function setUp() public {
        address lut = address(new Stable2LUT1());
        _f = new Stable2(lut);
        data = abi.encode(18, 18);
    }

    function test_calcReserveAtRatioSwap_equal_equal() public view {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 100e18;
        reserves[1] = 100e18;
        uint256[] memory ratios = new uint256[](2);
        ratios[0] = 1;
        ratios[1] = 1;

        uint256 reserve0 = _f.calcReserveAtRatioSwap(reserves, 0, ratios, data);
        uint256 reserve1 = _f.calcReserveAtRatioSwap(reserves, 1, ratios, data);

        assertEq(reserve0, 100.005058322101089709e18);
        assertEq(reserve1, 100.005058322101089709e18);
    }

    function test_calcReserveAtRatioSwap_equal_diff() public view {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 50e18;
        reserves[1] = 100e18;
        uint256[] memory ratios = new uint256[](2);
        ratios[0] = 1;
        ratios[1] = 1;

        uint256 reserve0 = _f.calcReserveAtRatioSwap(reserves, 0, ratios, data);
        uint256 reserve1 = _f.calcReserveAtRatioSwap(reserves, 1, ratios, data);

        assertEq(reserve0, 73.517644476151580971e18);
        assertEq(reserve1, 73.517644476151580971e18);
    }

    function test_calcReserveAtRatioSwap_diff_equal() public view {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 100e18;
        reserves[1] = 100e18;
        uint256[] memory ratios = new uint256[](2);
        ratios[0] = 2;
        ratios[1] = 1;

        uint256 reserve0 = _f.calcReserveAtRatioSwap(reserves, 0, ratios, data);
        uint256 reserve1 = _f.calcReserveAtRatioSwap(reserves, 1, ratios, data);

        assertEq(reserve0, 180.643950056605911775e18); // 180.64235400499155996e18, 100e18
        assertEq(reserve1, 39.474875366590812867e18); // 100e18, 39.474875366590812867e18
    }

    function test_calcReserveAtRatioSwap_diff_diff() public view {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 90e18;
        reserves[1] = 110e18;
        uint256[] memory ratios = new uint256[](2);
        ratios[0] = 110;
        ratios[1] = 90;

        uint256 reserve0 = _f.calcReserveAtRatioSwap(reserves, 0, ratios, data);
        uint256 reserve1 = _f.calcReserveAtRatioSwap(reserves, 1, ratios, data);

        assertEq(reserve0, 129.268187496764805614e18); // 129.268187496764805614e18, 90e18
        assertEq(reserve1, 73.11634314279891828e18); // 110e18, 73.116252343760233529e18
    }

    function test_calcReserveAtRatioSwap_fuzz(uint256[2] memory reserves, uint256[2] memory ratios) public view {
        for (uint256 i; i < 2; ++i) {
            // Upper bound is limited by stableSwap,
            // due to the stableswap reserves being extremely far apart.
            reserves[i] = bound(reserves[i], 1e18, 1e31);
            ratios[i] = bound(ratios[i], 1e18, 4e18);
        }

        // create 2 new reserves, one where reserve[0] is updated, and one where reserve[1] is updated.
        uint256[] memory updatedReserves = new uint256[](2);
        for (uint256 i; i < 2; ++i) {
            updatedReserves[i] = _f.calcReserveAtRatioSwap(uint2ToUintN(reserves), i, uint2ToUintN(ratios), data);
        }

        {
            uint256 targetPrice = ratios[0] * 1e6 / ratios[1];
            uint256 reservePrice0 = _f.calcRate(updatedReserves, 0, 1, data);

            // estimated price and actual price are within 0.015% in the worst case.
            assertApproxEqRel(reservePrice0, targetPrice, 0.00015e18, "reservePrice0 <> targetPrice");
        }
    }
}
