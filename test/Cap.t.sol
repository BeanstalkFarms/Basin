// pragma solidity ^0.8.20;

// import {IWell, TestHelper, console} from "test/TestHelper.sol";
// import {ABDKMathQuad, MultiFlowPump} from "src/pumps/MultiFlowPump.sol";
// import {from18, to18} from "test/pumps/PumpHelpers.sol";

// import {console} from "forge-std/console.sol";

// contract Cap is MultiFlowPump {
//     using ABDKMathQuad for uint256;

//     /**
//      * @param _maxPercentIncrease The maximum percent increase allowed in a single block. Must be in quadruple precision format (See {ABDKMathQuad}).
//      * @param _maxPercentDecrease The maximum percent decrease allowed in a single block. Must be in quadruple precision format (See {ABDKMathQuad}).
//      * @param _blockTime The block time in the current EVM in seconds.
//      * @param _alpha The geometric EMA constant. Must be in quadruple precision format (See {ABDKMathQuad}).
//      */
//     constructor(
//         bytes16 _maxPercentIncrease,
//         bytes16 _maxPercentDecrease,
//         uint256 _blockTime,
//         bytes16 _alpha
//     ) MultiFlowPump(_maxPercentIncrease, _maxPercentDecrease, _blockTime, _alpha) {}

//     function cap(
//         uint256 reserve,
//         uint256 lastReserve,
//         uint256 timePassed
//     ) external view returns (uint256 cappedReserve) {
//         _capReserve(lastReserve.fromUIntToLog2(), reserve.fromUIntToLog2(), timePassed.fromUInt());
//     }
// }

// contract CapTest is TestHelper {
//     Cap c;

//     function setUp() public {
//         c = new Cap(
//             from18(0.5e18),
//             from18(0.333333333333333333e18),
//             12,
//             from18(0.9e18)
//         );
//     }

//     function test_block() public {
//         {
//             return;
//         }
//         console.log(1);
//     }

//     function test_capp() public {
//         c.cap(283_749_187_489_128_471_892_891_758_192, 102_945_812_908_192_301_928_301, 10_000);
//     }
// }
