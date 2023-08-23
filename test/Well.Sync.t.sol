// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockToken, TestHelper, Balances, IERC20, IWellFunction} from "test/TestHelper.sol";
import {IWellErrors} from "src/interfaces/IWellErrors.sol";

contract WellSyncTest is TestHelper {
    event Sync(uint256[] reserves, uint256 lpAmountIn, address recipient);

    function setUp() public {
        setupWell(2);

        // Let `user` burn
        vm.startPrank(address(well));
        MockToken(address(tokens[0])).approve(address(user), type(uint256).max);
        MockToken(address(tokens[1])).approve(address(user), type(uint256).max);
        vm.stopPrank();
    }

    function test_initialized() public {
        Balances memory wellBalance = getBalances(address(well), well);
        assertEq(wellBalance.tokens[0], 1000 * 1e18);
        assertEq(wellBalance.tokens[1], 1000 * 1e18);
    }

    function test_syncDown_getSyncOut() public prank(user) {
        MockToken(address(tokens[0])).burnFrom(address(well), 1e18);
        MockToken(address(tokens[1])).burnFrom(address(well), 1e18);
        assertEq(well.getSyncOut(), 0);
    }

    function test_syncDown() public prank(user) {
        MockToken(address(tokens[0])).burnFrom(address(well), 1e18);
        MockToken(address(tokens[1])).burnFrom(address(well), 1e18);

        uint256[] memory expectedReserves = new uint256[](2);
        expectedReserves[0] = 999e18;
        expectedReserves[1] = 999e18;

        uint256 lpTokenSupplyBefore = well.totalSupply();

        vm.expectEmit(true, true, true, true);
        emit Sync(expectedReserves, 0, address(user));

        uint256 lpAmountOut = well.sync(address(user), 0);

        uint256[] memory reserves = well.getReserves();
        assertEq(reserves[0], expectedReserves[0], "Reserve 0 should be 1e18");
        assertEq(reserves[1], expectedReserves[1], "Reserve 1 should be 1e18");
        assertEq(well.totalSupply(), lpTokenSupplyBefore, "LP token supply should not increase");
        assertEq(lpAmountOut, 0, "return value should be 0");
    }

    function test_syncDown_revert_minAmountOutTooHigh() public prank(user) {
        MockToken(address(tokens[0])).burnFrom(address(well), 1e18);
        MockToken(address(tokens[1])).burnFrom(address(well), 1e18);
        vm.expectRevert(abi.encodeWithSelector(IWellErrors.SlippageOut.selector, 0, 1));
        well.sync(address(user), 1);
    }

    function test_syncUp_getSyncOut() public prank(user) {
        uint256[] memory tokenAmountsIn = new uint256[](2);
        tokenAmountsIn[0] = 1e18;
        tokenAmountsIn[1] = 1e18;
        uint256 expectedLpAmountOut = well.getAddLiquidityOut(tokenAmountsIn);

        MockToken(address(tokens[0])).mint(address(well), 1e18);
        MockToken(address(tokens[1])).mint(address(well), 1e18);

        assertEq(well.getSyncOut(), expectedLpAmountOut);
    }

    function test_syncUp() public prank(user) {
        uint256[] memory tokenAmountsIn = new uint256[](2);
        tokenAmountsIn[0] = 1e18;
        tokenAmountsIn[1] = 1e18;
        uint256 minLpAmountOut = well.getAddLiquidityOut(tokenAmountsIn);

        MockToken(address(tokens[0])).mint(address(well), 1e18);
        MockToken(address(tokens[1])).mint(address(well), 1e18);

        uint256[] memory expectedReserves = new uint256[](2);
        expectedReserves[0] = 1001e18;
        expectedReserves[1] = 1001e18;

        uint256 newLpTokenSupply = IWellFunction(wellFunction.target).calcLpTokenSupply(expectedReserves, "");
        uint256 expectedLpAmountOut = newLpTokenSupply - well.totalSupply();

        vm.expectEmit(true, true, true, true);
        emit Sync(expectedReserves, expectedLpAmountOut, address(user));

        uint256 lpAmountOut = well.sync(address(user), minLpAmountOut);

        uint256[] memory reserves = well.getReserves();
        assertEq(reserves[0], expectedReserves[0], "Reserve 0 should be Balance 0");
        assertEq(reserves[1], expectedReserves[1], "Reserve 1 should be Balance 1");
        assertEq(well.totalSupply(), newLpTokenSupply, "LP token supply should be newLpTokenSupply");
        assertEq(lpAmountOut, expectedLpAmountOut, "return value should be expected LP amount out");
    }

    function test_syncUp_revert_minAmountOutTooHigh() public prank(user) {
        uint256[] memory tokenAmountsIn = new uint256[](2);
        tokenAmountsIn[0] = 1e18;
        tokenAmountsIn[1] = 1e18;
        uint256 minLpAmountOut = well.getAddLiquidityOut(tokenAmountsIn);

        MockToken(address(tokens[0])).mint(address(well), 1e18);
        MockToken(address(tokens[1])).mint(address(well), 1e18);

        vm.expectRevert(abi.encodeWithSelector(IWellErrors.SlippageOut.selector, minLpAmountOut, minLpAmountOut + 1));
        well.sync(address(user), minLpAmountOut + 1);
    }

    function testFuzz_sync(uint96[2] calldata mintAmount, uint96[2] calldata burnAmount) public prank(user) {
        uint256 temp = bound(mintAmount[0], 0, type(uint96).max - tokens[0].balanceOf(address(well)) - 100);
        MockToken(address(tokens[0])).mint(address(well), temp);
        temp = bound(mintAmount[1], 0, type(uint96).max - tokens[1].balanceOf(address(well)) - 100);
        MockToken(address(tokens[1])).mint(address(well), temp);
        temp = bound(burnAmount[0], 0, tokens[0].balanceOf(address(well)));
        MockToken(address(tokens[0])).burnFrom(address(well), temp);
        temp = bound(burnAmount[1], 0, tokens[1].balanceOf(address(well)));
        MockToken(address(tokens[1])).burnFrom(address(well), temp);

        uint256[] memory balances = new uint256[](2);
        balances[0] = tokens[0].balanceOf(address(well));
        balances[1] = tokens[1].balanceOf(address(well));

        uint256 expectedLpAmountOut;
        uint256 newLpTokenSupply = IWellFunction(wellFunction.target).calcLpTokenSupply(balances, "");
        if (newLpTokenSupply > well.totalSupply()) {
            expectedLpAmountOut = newLpTokenSupply - well.totalSupply();
        } else {
            newLpTokenSupply = well.totalSupply();
        }

        vm.expectEmit(true, true, true, true);
        emit Sync(balances, expectedLpAmountOut, address(user));

        uint256 lpAmountOut = well.sync(address(user), 0);

        uint256[] memory reserves = well.getReserves();
        assertEq(reserves[0], balances[0], "Reserve 0 should be Balance 0");
        assertEq(reserves[1], balances[1], "Reserve 1 should be Balance 1");
        assertEq(well.totalSupply(), newLpTokenSupply, "LP token supply should be newLpTokenSupply");
        assertEq(lpAmountOut, expectedLpAmountOut, "return value should be expected LP amount out");
    }

    function test_sync_removeLiquidityImbalanced() public {
        IERC20[] memory tokens = well.tokens();
        Balances memory userBalance;

        mintTokens(user, 10_000_000e18);

        vm.startPrank(user);
        tokens[0].transfer(address(well), 100);
        tokens[1].transfer(address(well), 100);
        vm.stopPrank();

        userBalance = getBalances(user, well);

        addLiquidityEqualAmount(user, 1);

        userBalance = getBalances(user, well);
        well.sync(address(user), 0); // reserves = [101, 101]

        uint256[] memory amounts = new uint256[](tokens.length);
        amounts[0] = 1;

        vm.prank(user);
        amounts[0] = 1;
        well.removeLiquidityImbalanced(type(uint256).max, amounts, user, type(uint256).max);
    }
}
