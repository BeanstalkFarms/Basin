// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TestHelper, Well, IERC20, console} from "test/TestHelper.sol";
import {Stable2LUT1} from "src/functions/StableLut/Stable2LUT1.sol";

contract LookupTableTest is TestHelper {
    Stable2LUT1 lookupTable;
    Stable2LUT1.PriceData pd;

    function setUp() public {
        lookupTable = new Stable2LUT1();
    }

    function test_getAParameter() public {
        uint256 a = lookupTable.getAParameter();
        assertEq(a, 1);
    }

    //////////////// getRatiosFromPriceSwap ////////////////

    function test_getRatiosFromPriceSwapAroundDollarHigh() public {
        uint256 currentPrice = 1e6;
        // test 1.0 - 1.10 range
        for (uint256 i; i < 10; i++) {
            pd = lookupTable.getRatiosFromPriceSwap(currentPrice);
            uint256 diff = pd.highPrice - pd.lowPrice;
            assertLt(diff, 0.08e6);
            currentPrice += 0.01e6;
        }
    }

    function test_getRatiosFromPriceSwapAroundDollarLow() public {
        uint256 currentPrice = 0.9e6;
        // test 0.9 - 1.0 range
        for (uint256 i; i < 10; i++) {
            pd = lookupTable.getRatiosFromPriceSwap(currentPrice);
            uint256 diff = pd.highPrice - pd.lowPrice;
            assertLt(diff, 0.08e18);
            currentPrice += 0.01e6;
        }
    }

    function test_getRatiosFromPriceSwapExtremeLow() public {
        // pick a value close to the min (P=0.01)
        uint256 currentPrice = 0.015e6;
        pd = lookupTable.getRatiosFromPriceSwap(currentPrice);
        console.log("pd.lowPrice: %e", pd.lowPrice);
        console.log("pd.highPrice: %e", pd.highPrice);
    }

    function test_getRatiosFromPriceSwapExtremeHigh() public {
        // pick a value close to the max (P=9.85)
        uint256 currentPrice = 9.84e6;
        pd = lookupTable.getRatiosFromPriceSwap(currentPrice);
        console.log("pd.lowPrice: %e", pd.lowPrice);
        console.log("pd.highPrice: %e", pd.highPrice);
    }

    function testFail_getRatiosFromPriceSwapExtremeLow() public {
        // pick an out of bounds value (P<0.01)
        uint256 currentPrice = 0.001e6;
        pd = lookupTable.getRatiosFromPriceSwap(currentPrice);
    }

    function testFail_getRatiosFromPriceSwapExtremeHigh() public {
        // pick an out of bounds value (P>9.85)
        uint256 currentPrice = 10e6;
        pd = lookupTable.getRatiosFromPriceSwap(currentPrice);
    }

    //////////////// getRatiosFromPriceLiquidity ////////////////

    function test_getRatiosFromPriceLiquidityAroundDollarHigh() public {
        uint256 currentPrice = 1e6;
        // test 1.0 - 1.10 range
        for (uint256 i; i < 10; i++) {
            pd = lookupTable.getRatiosFromPriceLiquidity(currentPrice);
            uint256 diff = pd.highPrice - pd.lowPrice;
            assertLt(diff, 0.08e6);
            currentPrice += 0.01e6;
        }
    }

    function test_getRatiosFromPriceLiquidityAroundDollarLow() public {
        uint256 currentPrice = 0.9e6;
        // test 0.9 - 1.0 range
        for (uint256 i; i < 10; i++) {
            pd = lookupTable.getRatiosFromPriceLiquidity(currentPrice);
            uint256 diff = pd.highPrice - pd.lowPrice;
            assertLt(diff, 0.1e6);
            currentPrice += 0.01e6;
        }
    }

    function test_getRatiosFromPriceLiquidityExtremeLow() public {
        // pick a value close to the min (P=0.01)
        uint256 currentPrice = 0.015e6;
        pd = lookupTable.getRatiosFromPriceLiquidity(currentPrice);
        console.log("pd.lowPrice: %e", pd.lowPrice);
        console.log("pd.highPrice: %e", pd.highPrice);
    }

    function test_getRatiosFromPriceLiquidityExtremeHigh() public {
        // pick a value close to the max (P=9.92)
        uint256 currentPrice = 9.91e6;
        pd = lookupTable.getRatiosFromPriceLiquidity(currentPrice);
        console.log("pd.lowPrice: %e", pd.lowPrice);
        console.log("pd.highPrice: %e", pd.highPrice);
    }

    function testFail_getRatiosFromPriceLiquidityExtremeLow() public {
        // pick an out of bounds value (P<0.01)
        uint256 currentPrice = 0.001e6;
        pd = lookupTable.getRatiosFromPriceLiquidity(currentPrice);
    }

    function testFail_getRatiosFromPriceLiquidityExtremeHigh() public {
        // pick an out of bounds value (P>9.85)
        uint256 currentPrice = 10e6;
        pd = lookupTable.getRatiosFromPriceLiquidity(currentPrice);
    }

    ////////////////// Price Range Tests //////////////////

    function test_PriceRangeSwap() public {
        // test range 0.5 - 2.5
        uint256 currentPrice = 0.5e6;
        for (uint256 i; i < 200; i++) {
            pd = lookupTable.getRatiosFromPriceSwap(currentPrice);
            assertGe(pd.highPrice, currentPrice);
            assertLt(pd.lowPrice, currentPrice);
            currentPrice += 0.01e6;
        }
    }

    function test_PriceRangeLiq() public {
        // test range 0.5 - 2.5
        uint256 currentPrice = 0.5e6;
        for (uint256 i; i < 200; i++) {
            pd = lookupTable.getRatiosFromPriceLiquidity(currentPrice);
            assertGe(pd.highPrice, currentPrice);
            assertLt(pd.lowPrice, currentPrice);
            currentPrice += 0.01e6;
        }
    }
}
