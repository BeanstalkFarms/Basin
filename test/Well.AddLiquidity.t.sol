/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";


contract AddLiquidityTest is TestHelper {

    event AddLiquidity(uint[] tokenAmountsIn, uint lpAmountOut);

    function setUp() public {
        setupWell(2);
    }

    function testGetAddLiquidityOutEqual() public {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) amounts[i] = 1000 * 1e18;

        uint amountOut = well.getAddLiquidityOut(amounts);
        assertEq(amountOut, 2000 * 1e18);
    }

    function testAddLiquidityEqual() prank(user) public {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) amounts[i] = 1000 * 1e18;
        uint amountOut = 2000 * 1e18;

        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts,amountOut);

        well.addLiquidity(amounts, amountOut, user);

        assertEq(well.balanceOf(user), amountOut);

        assertEq(tokens[0].balanceOf(user), 0);
        assertEq(tokens[1].balanceOf(user), 0);

        assertEq(tokens[0].balanceOf(address(well)), 2000 * 1e18);
        assertEq(tokens[1].balanceOf(address(well)), 2000 * 1e18);
    }

    function testGetAddLiquidityOutOne() public {
        uint[] memory amounts = new uint[](2);
        amounts[0] = 10 * 1e18;
        amounts[1] = 0;

        uint amountOut = well.getAddLiquidityOut(amounts);
        assertEq(amountOut, 9975124224178054042);
    }

    function testAddLiquidityOne() prank(user) public {
        uint[] memory amounts = new uint[](2);
        amounts[0] = 10 * 1e18;
        amounts[1] = 0;

        uint amountOut = 9975124224178054042;

        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts, amountOut);

        well.addLiquidity(amounts, 0, user);

        assertEq(well.balanceOf(user), amountOut);

        assertEq(tokens[0].balanceOf(user), 990 * 1e18);
        assertEq(tokens[1].balanceOf(user), 1000 * 1e18);

        assertEq(tokens[0].balanceOf(address(well)), 1010 * 1e18);
        assertEq(tokens[1].balanceOf(address(well)), 1000 * 1e18);
    }

    function testAddMinAmountOutTooHigh() prank(user) public {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) amounts[i] = 1000 * 1e18;
        vm.expectRevert("Well: slippage");
        well.addLiquidity(amounts, 2001*1e18, user);
    }
}
