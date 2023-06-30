// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.17;

// import {console, TestHelper, IERC20} from "test/TestHelper.sol";
// import {BeanstalkStableSwap} from "src/functions/BeanstalkStableSwap.sol";
// import {IBeanstalkWellFunction} from "src/interfaces/IBeanstalkWellFunction.sol";


// /// @dev Tests the {ConstantProduct2} Well function directly.
// contract BeanstalkStableSwapSwapTest is TestHelper {
//     IBeanstalkWellFunction _f;
//     bytes data;

//     //////////// SETUP ////////////

//     function setUp() public {
//         _f = new BeanstalkStableSwap();
//         IERC20[] memory _token =  deployMockTokens(2);
//         data = abi.encode(
//             address(_token[0]), 
//             address(_token[1])
//         );
//     }

//     function test_calcReserveAtRatioSwap_equal_equal() public {
//         uint256[] memory reserves = new uint256[](2);
//         reserves[0] = 100;
//         reserves[1] = 100;
//         uint256[] memory ratios = new uint256[](2);
//         ratios[0] = 1;
//         ratios[1] = 1;

//         uint256 reserve0 = _f.calcReserveAtRatioSwap(reserves, 0, ratios, data);
//         uint256 reserve1 = _f.calcReserveAtRatioSwap(reserves, 1, ratios, data);

//         assertEq(reserve0, 100);
//         assertEq(reserve1, 100);
//     }

//     function test_calcReserveAtRatioSwap_equal_diff() public {
//         uint256[] memory reserves = new uint256[](2);
//         reserves[0] = 50;
//         reserves[1] = 100;
//         uint256[] memory ratios = new uint256[](2);
//         ratios[0] = 1;
//         ratios[1] = 1;

//         uint256 reserve0 = _f.calcReserveAtRatioSwap(reserves, 0, ratios, data);
//         uint256 reserve1 = _f.calcReserveAtRatioSwap(reserves, 1, ratios, data);

//         assertEq(reserve0, 74);
//         assertEq(reserve1, 74);
//     }

//     function test_calcReserveAtRatioSwap_diff_equal() public {
//         uint256[] memory reserves = new uint256[](2);
//         reserves[0] = 100;
//         reserves[1] = 100;
//         uint256[] memory ratios = new uint256[](2);
//         ratios[0] = 2;
//         ratios[1] = 1;

//         uint256 reserve0 = _f.calcReserveAtRatioSwap(reserves, 0, ratios, data);
//         uint256 reserve1 = _f.calcReserveAtRatioSwap(reserves, 1, ratios, data);

//         assertEq(reserve0, 141);
//         assertEq(reserve1, 70);
//     }

//     function test_calcReserveAtRatioSwap_diff_diff() public {
//         uint256[] memory reserves = new uint256[](2);
//         reserves[0] = 50;
//         reserves[1] = 100;
//         uint256[] memory ratios = new uint256[](2);
//         ratios[0] = 12_984_712_098_520;
//         ratios[1] = 12_984_712_098;

//         uint256 reserve0 = _f.calcReserveAtRatioSwap(reserves, 0, ratios, data);
//         uint256 reserve1 = _f.calcReserveAtRatioSwap(reserves, 1, ratios, data);

//         assertEq(reserve0, 2236);
//         assertEq(reserve1, 2);
//     }

//     function test_calcReserveAtRatioSwap_fuzz(uint256[2] memory reserves, uint256[2] memory ratios) public {
//         // Upper bound is limited by stableSwap,
//         // due to the stableswap reserves being extremely far apart.
//         reserves[0] = bound(reserves[0], 1e18, 1e31);
//         reserves[1] = bound(reserves[1], 1e18, 1e31);
//         ratios[0] = 1e18;
//         ratios[1] = 2e18;


//         uint256 lpTokenSupply = _f.calcLpTokenSupply(uint2ToUintN(reserves), data);
//         console.log("lpTokenSupply:", lpTokenSupply);

//         uint256[] memory reservesOut = new uint256[](2);
//         for (uint256 i; i < 2; ++i) {
//             reservesOut[i] = _f.calcReserveAtRatioSwap(uint2ToUintN(reserves), i, uint2ToUintN(ratios), data);
//         }
//         console.log("reservesOut 0:", reservesOut[0]);
//         console.log("reservesOut 1:", reservesOut[1]);


//         // Get LP token supply with bound reserves.
//         uint256 lpTokenSupplyOut = _f.calcLpTokenSupply(reservesOut, data);
//         console.log("lpTokenSupplyOut:", lpTokenSupplyOut);
//         // Precision is set to the minimum number of digits of the reserves out.
//         uint256 precision = numDigits(reservesOut[0]) > numDigits(reservesOut[1])
//             ? numDigits(reservesOut[1])
//             : numDigits(reservesOut[0]);

//         // Check LP Token Supply after = lp token supply before.
//         // assertApproxEq(lpTokenSupplyOut, lpTokenSupply, 2, precision);
//         assertApproxEqRel(lpTokenSupplyOut,lpTokenSupply, 0.01*1e18);

//         // Check ratio of `reservesOut` = ratio of `ratios`.
//         // assertApproxEqRelN(reservesOut[0] * ratios[1], ratios[0] * reservesOut[1], 2, precision);
//     }
// }
