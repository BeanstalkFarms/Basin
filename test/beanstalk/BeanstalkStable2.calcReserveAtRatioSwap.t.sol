// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {console, TestHelper, IERC20} from "test/TestHelper.sol";
import {Stable2} from "src/functions/Stable2.sol";
import {IBeanstalkWellFunction} from "src/interfaces/IBeanstalkWellFunction.sol";
import {Stable2LUT1} from "src/functions/StableLUT/Stable2LUT1.sol";

/// @dev Tests the {ConstantProduct2} Well function directly.
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
        // calcReserveAtRatioSwap requires a minimum value of 10 ** token decimals.
        reserves[0] = 100e18;
        reserves[1] = 100e18;
        uint256[] memory ratios = new uint256[](2);
        ratios[0] = 1;
        ratios[1] = 1;

        uint256 reserve0 = _f.calcReserveAtRatioSwap(reserves, 0, ratios, data);
        uint256 reserve1 = _f.calcReserveAtRatioSwap(reserves, 1, ratios, data);

        assertEq(reserve0, 100e18);
        assertEq(reserve1, 100e18);
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

        // assertEq(reserve0, 74); // 50
        // assertEq(reserve1, 74); // 100
        console.log("reserve0", reserve0);
        console.log("reserve1", reserve1);
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

        // assertEq(reserve0, 149);
        // assertEq(reserve1, 74);
        console.log("reserve0", reserve0);
        console.log("reserve1", reserve1);
    }

    function test_calcReserveAtRatioSwap_diff_diff() public view {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 90; // bean
        reserves[1] = 110; // usdc
        uint256[] memory ratios = new uint256[](2);
        ratios[0] = 110;
        ratios[1] = 90;

        uint256 reserve0 = _f.calcReserveAtRatioSwap(reserves, 0, ratios, data);
        uint256 reserve1 = _f.calcReserveAtRatioSwap(reserves, 1, ratios, data);

        // assertEq(reserve0, 110);
        // assertEq(reserve1, 91);
        console.log("reserve0", reserve0);
        console.log("reserve1", reserve1);
    }
}
