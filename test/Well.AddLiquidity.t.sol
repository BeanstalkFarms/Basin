/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "test/TestHelper.sol";

import "src/functions/ConstantProduct2.sol";

import "forge-std/console.sol";


contract AddLiquidityTest is TestHelper {
    ConstantProduct2 cp;

    event AddLiquidity(uint[] tokenAmountsIn, uint lpAmountOut);
    event RemoveLiquidity(uint lpAmountIn,uint[] tokenAmountsOut);

    function setUp() public {
        setupWell(2);
    }

    function testGetAddLiquidityOutEqual() public {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) amounts[i] = 1000 * 1e18;

        uint amountOut = well.getAddLiquidityOut(amounts);
        assertEq(amountOut, 2000 * 1e27, "Incorrect AmountOut");
    }

    function testAddLiquidityEqual() prank(user) public {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) amounts[i] = 1000 * 1e18;
        uint amountOut = 2000 * 1e27;

        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts,amountOut);

        well.addLiquidity(amounts, amountOut, user);

        assertEq(well.balanceOf(user), amountOut);

        assertEq(tokens[0].balanceOf(user), 0, "incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user), 0, "incorrect token1 user amt");

        assertEq(tokens[0].balanceOf(address(well)), 2000 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 2000 * 1e18, "incorrect token1 well amt");
    }

    function testGetAddLiquidityOutOne() public {
        uint[] memory amounts = new uint[](2);
        amounts[0] = 10 * 1e18;
        amounts[1] = 0;

        uint amountOut = well.getAddLiquidityOut(amounts);
        assertEq(amountOut, 9975124224178054043852982550, "incorrect amt out");
    }

    function testAddLiquidityOne() prank(user) public {
        uint[] memory amounts = new uint[](2);
        amounts[0] = 10 * 1e18;
        amounts[1] = 0;

        uint amountOut = 9975124224178054043852982550;

        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts, amountOut);

        well.addLiquidity(amounts, 0, user);

        assertEq(well.balanceOf(user), amountOut, "incorrect well user balance");

        assertEq(tokens[0].balanceOf(user), 990 * 1e18, "incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user), 1000 * 1e18, "incorrect token1 user amt");

        assertEq(tokens[0].balanceOf(address(well)), 1010 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 1000 * 1e18, "incorrect token1 well amt");
    }

    function testAddMinAmountOutTooHigh() prank(user) public {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) amounts[i] = 1000 * 1e18;
        vm.expectRevert("Well: slippage");
        well.addLiquidity(amounts, 2001*1e27, user);
    }

    function testAddAndRemoveLiquidity() prank(user) public {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) amounts[i] = 1000 * 1e18;
        uint liquidity = 2000 * 1e27;

        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts,liquidity);

        well.addLiquidity(amounts, liquidity, user);

        assertEq(well.balanceOf(user), liquidity);

        assertEq(tokens[0].balanceOf(user), 0, "incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user), 0, "incorrect token1 user amt");

        assertEq(tokens[0].balanceOf(address(well)), 2000 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 2000 * 1e18, "incorrect token1 well amt");

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(liquidity, amounts);

        well.removeLiquidity(liquidity, amounts, user);

        assertEq(well.balanceOf(user), 0, "incorrect well user amt");
        assertEq(tokens[0].balanceOf(user), amounts[0],"incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user), amounts[1], "incorrect token1 user amt");
        assertEq(tokens[0].balanceOf(address(well)), 1000 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 1000 * 1e18, "incorrect token1 well amt");

    }

    function testAddZeroLiquidity() prank(user) public {
        uint[] memory amounts = new uint[](tokens.length);
        uint liquidity = 0;

        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts,liquidity);

        well.addLiquidity(amounts, liquidity, user);

        assertEq(well.balanceOf(user), 0, "incorrect well user amt");
        assertEq(tokens[0].balanceOf(user), 1000 * 1e18,"incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user), 1000 * 1e18, "incorrect token1 user amt");
        assertEq(tokens[0].balanceOf(address(well)), 1000 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 1000 * 1e18, "incorrect token1 well amt");
    }

    function testAddLiqudityFuzz(uint x, uint y) prank(user) public {
        uint[] memory amounts = new uint[](2);
        amounts[0] = bound(x,0,1000e18);
        amounts[1] = bound(y,0,1000e18);
        cp = new ConstantProduct2();
        bytes memory data = "";
        uint[] memory balances = new uint[](2);
        balances[0] = amounts[0] + tokens[0].balanceOf(address(well));
        balances[1] = amounts[1] + tokens[1].balanceOf(address(well));

        uint newLpTokenSupply =  cp.getLpTokenSupply(balances,data);
        uint totalSupply = well.totalSupply();
        uint amountOut = newLpTokenSupply - totalSupply;
        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts, amountOut);

        well.addLiquidity(amounts, 0, user);

        assertEq(well.balanceOf(user), amountOut,"incorrect well user amt");
        assertEq(tokens[0].balanceOf(user),1000e18 - amounts[0],"incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user),1000e18 - amounts[1], "incorrect token1 user amt");
        assertEq(tokens[0].balanceOf(address(well)), 1000e18 + amounts[0], "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 1000e18 + amounts[1], "incorrect token1 well amt");
    }
}
