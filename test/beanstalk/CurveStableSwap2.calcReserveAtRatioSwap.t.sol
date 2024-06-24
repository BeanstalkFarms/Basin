// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {console, TestHelper, IERC20} from "test/TestHelper.sol";
import {CurveStableSwap2} from "src/functions/CurveStableSwap2.sol";
import {IBeanstalkWellFunction} from "src/interfaces/IBeanstalkWellFunction.sol";

/// @dev Tests the {ConstantProduct2} Well function directly.
contract BeanstalkStableSwapSwapTest is TestHelper {
    IBeanstalkWellFunction _f;
    bytes data;

    //////////// SETUP ////////////

    function setUp() public {
        _f = new CurveStableSwap2();
        IERC20[] memory _token = deployMockTokens(2);
        data = abi.encode(10, address(_token[0]), address(_token[1]));
    }

    function test_calcReserveAtRatioSwap_equal_equal() public {
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

    function test_calcReserveAtRatioSwap_equal_diff() public {
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

    function test_calcReserveAtRatioSwap_diff_equal() public {
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

    function test_calcReserveAtRatioSwap_diff_diff() public {
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
