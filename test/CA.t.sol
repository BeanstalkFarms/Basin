pragma solidity ^0.8.20;

import {console, IWell, TestHelper, console} from "test/TestHelper.sol";
// import "src/libraries/LibBytes16.sol";
// import "src/libraries/LibLastReserveBytes.sol";

// import "src/functions/ConstantProduct2.sol";

contract CA {
    function aa() public view returns (uint256) {
        return type(uint128).max;
    }

    function bb() public view returns (uint256) {
        return 3.4028236692e38;
    }
}

contract CATest is TestHelper {
    function test_ab() public {
        CA ca = new CA();
        ca.aa();
        ca.bb();
        console.log(type(uint128).max);
    }
}
//     using LibBytes16 for bytes32;
//     using LibLastReserveBytes for bytes32;

//     bytes32 public storageSlot;

//     function setUp() public {
//         setupWell(2);
//     }

//     function testBugBytes16() public {
//         // for (uint n; n < 512; ++n) {
//         uint n = 65;
//         bytes16[] memory reserves = new bytes16[](n);
//         for (uint i; i < reserves.length; i++) {
//             reserves[i] = bytes16(uint128(i));
//         }
//         storageSlot.storeBytes16(reserves);

//         bytes16[] memory storedReserves = storageSlot.readBytes16(n);

//         for (uint i; i < storedReserves.length; ++i) {
//             console.log("------------------");
//             console.logBytes16(storedReserves[i]);
//             console.logBytes16(reserves[i]);
//             assertEq(storedReserves[i], reserves[i]);
//         }
//         // }
//     }

//     function testBugLastReserves() public {
//         // for (uint n; n < 512; ++n) {
//         uint n = 65;
//         bytes16[] memory reserves = new bytes16[](n);
//         for (uint i; i < reserves.length; i++) {
//             reserves[i] = bytes16(uint128(i*100000000000000));
//         }
//         storageSlot.storeLastReserves(1, reserves);

//         (,,bytes16[] memory storedReserves) = storageSlot.readLastReserves();

//         for (uint i; i < storedReserves.length; ++i) {
//             console.log("------------------");
//             console.logBytes16(storedReserves[i]);
//             console.logBytes16(reserves[i]);
//             // assertEq(storedReserves[i], reserves[i]);
//         }
//         // }
//     }

//     function testA() public prank(user) {
//         uint256[] memory initialReserves = new uint256[](2);
//         initialReserves[0] = 1_000_000_000;
//         initialReserves[1] = 1_000;
//         mintAndAddLiquidity(user, initialReserves);
//         mintTokens(user, 1e50);

//         for (uint i; i < 1001; ++i) {
//             well.swapFrom(
//                 tokens[0],
//                 tokens[1],
//                 10_000_000,
//                 0,
//                 user,
//                 type(uint256).max
//             );
//         }
//         uint256[] memory reserves = well.getReserves();
//         console.log(reserves[0]);
//         console.log(reserves[1]);
//         console.log("TS", well.totalSupply());
//         console.log("LPTS", ConstantProduct2(wellFunction.target).calcLpTokenSupply(reserves, new bytes(0)));
//     }

//     // function testBytes16DirtyBytes() public {
//     //     uint256 a = type(uint256).max;
//     //     bytes16 b;
//     //     bytes16 c = bytes16(type(uint128).max);
//     //     bytes16[] memory b2 = new bytes16[](1);
//     //     assembly {
//     //         sstore(0, a)
//     //         sstore(1, a)
//     //         b := sload(0)
//     //         mstore(add(b2, 32), b)
//     //     }

//     //     console.log('-----b------');
//     //     console.logBytes16(b);
//     //     console.log(uint128(b));
//     //     console.log(uint(uint128(b)));
//     //     console.logBytes32(bytes32(b));
//     //     console.log(uint256(bytes32(b)));
//     //     console.log('-----b2[0]------');
//     //     console.logBytes16(b2[0]);
//     //     console.log(uint128(b2[0]));
//     //     console.log(uint(uint128(b2[0])));
//     //     console.logBytes32(bytes32(b2[0]));
//     //     console.log(uint256(bytes32(b2[0])));
//     //     console.log('-----c------');
//     //     console.logBytes16(c);
//     //     console.log(uint128(c));
//     //     console.log(uint(uint128(c)));
//     //     console.logBytes32(bytes32(c));
//     //     console.log(uint256(bytes32(c)));
//     // }

//     function testBytes16DirtyBytes() public {
//         uint256 a = type(uint256).max;
//         bytes16[] memory b2 = new bytes16[](1);
//         assembly {
//             sstore(0, a)
//             mstore(add(b2, 32), sload(0))
//         }
//         console.logBytes16(b2[0]);
//         console.logBytes32(bytes32(b2[0]));
//         console.log(uint256(uint128(b2[0])));
//     }

//     function testD() public {
//         IWell fb = IWell(address(new Fb()));
//         try fb.isInitialized() returns (bool isInitialized) {
//             console.log(2);

//         } catch (bytes memory) {
//             console.log(1);
//         }
//     }

// }

// contract Fb {
//     fallback() external payable {
//     }
// }
