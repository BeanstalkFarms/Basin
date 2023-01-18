// /**
//  * SPDX-License-Identifier: MIT
//  **/
// pragma solidity ^0.8.17;

// import "test/TestHelper.sol";

// contract WellBuilderTest is TestHelper {

//     address[] wells;

//     event AddLiquidity(uint[] amounts);

//     function setUp() public {
//         initUser();
//         deployMockTokens(10);
//         wellBuilder = new WellBuilder();
//         Call memory wf = Call(address(new ConstantProduct()), new bytes(0));
//         Call memory pump;
//         wells.push(wellBuilder.buildWell(getTokens(2), wf, pump));
//         wells.push(wellBuilder.buildWell(getTokens(2), wf, pump));
//         wells.push(wellBuilder.buildWell(getTokens(3), wf, pump));
//     }

//     function testGetWellsBy2Tokens() external {
//         address[] memory _wells = wellBuilder.getWellsBy2Tokens(tokens[0], tokens[1]);
//         assertEq(_wells[0], wells[0]);
//         assertEq(_wells[1], wells[1]);
//         assertEq(_wells[2], wells[2]);
//     }

//     function testGetWellBy2Tokens() external {
//         address _well = wellBuilder.getWellBy2Tokens(tokens[0], tokens[1], 0);
//         assertEq(_well, wells[0]);
//         _well = wellBuilder.getWellBy2Tokens(tokens[0], tokens[1], 1);
//         assertEq(_well, wells[1]);
//         _well = wellBuilder.getWellBy2Tokens(tokens[0], tokens[1], 2);
//         assertEq(_well, wells[2]);
//         _well = wellBuilder.getWellBy2Tokens(tokens[1], tokens[2], 0);
//         assertEq(_well, wells[2]);
//         _well = wellBuilder.getWellBy2Tokens(tokens[0], tokens[2], 0);
//         assertEq(_well, wells[2]);
//     }

//     function testGetWellByNTokens() external {
//         address _well = wellBuilder.getWellByNTokens(getTokens(2), 0);
//         assertEq(_well, wells[0]);
//         _well = wellBuilder.getWellByNTokens(getTokens(2), 1);
//         assertEq(_well, wells[1]);
//         _well = wellBuilder.getWellByNTokens(getTokens(3), 0);
//         assertEq(_well, wells[2]);
//     }

//     function testGetWellsByNTokens() external {
//         address[] memory _wells = wellBuilder.getWellsByNTokens(getTokens(2));
//         assertEq(_wells[0], wells[0]);
//         assertEq(_wells[1], wells[1]);
//         _wells = wellBuilder.getWellsByNTokens(getTokens(3));
//         assertEq(_wells[0], wells[2]);
//     }
// }
