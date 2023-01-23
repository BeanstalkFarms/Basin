/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "test/TestHelper.sol";

import "src/functions/ConstantProduct2.sol";

import "forge-std/console.sol";


contract WellAddLiquidityTest is TestHelper {

    event AddLiquidity(uint[] tokenAmountsIn, uint lpAmountOut);
    event RemoveLiquidity(uint lpAmountIn,uint[] tokenAmountsOut);

    function setUp() public {
        setupWell(2);
    }

    /// @dev liquidity is initially added in {TestHelper}
    /// this will ensure that subsequent tests run correctly.
    function test_liquidityInitialized() public {
        IERC20[] memory tokens = well.tokens();
        for(uint i = 0; i < tokens.length; i++) {
            assertEq(tokens[i].balanceOf(address(well)), 1000 * 1e18, "incorrect token reserve");
        }
    }

    /// @dev getAddLiquidityOut: equal amounts.
    /// adding liquidity in equal proportions should summate and be
    /// scaled up by sqrt(ConstantProduct2.EXP_PRECISION)
    function test_getAddLiquidityOut_equalAmounts() public {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) amounts[i] = 1000 * 1e18;
        uint lpAmountOut = well.getAddLiquidityOut(amounts);
        assertEq(lpAmountOut, 2000 * 1e27, "Incorrect AmountOut");
    }

    /// @dev addLiquidity: equal amounts.
    function test_addLiquidity_equalAmounts() prank(user) public {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) amounts[i] = 1000 * 1e18;
        uint lpAmountOut = 2000 * 1e27;

        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts, lpAmountOut);
        well.addLiquidity(amounts, lpAmountOut, user);

        assertEq(well.balanceOf(user), lpAmountOut);
        
        // Consumes all of user's tokens
        // FIXME: 1000 * 1e18 is minted in TestHelper, make this a constant?
        assertEq(tokens[0].balanceOf(user), 0, "incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user), 0, "incorrect token1 user amt");

        // Adds to the Well's reserves
        // FIXME: need to know that TestHelper adds an initial 1000 * 1e18
        assertEq(tokens[0].balanceOf(address(well)), 2000 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 2000 * 1e18, "incorrect token1 well amt");
    }

    /// @dev getAddLiquidityOut: one-sided.
    function test_getAddLiquidityOut_oneToken() public {
        uint[] memory amounts = new uint[](2);
        amounts[0] = 10 * 1e18;
        amounts[1] = 0;

        uint amountOut = well.getAddLiquidityOut(amounts);
        assertEq(amountOut, 9975124224178054043852982550, "incorrect amt out");
    }

    /// @dev addLiquidity: one-sided.
    function test_addLiquidity_oneToken() prank(user) public {
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

    /// @dev addLiquidity: reverts for slippage
    function test_addLiquidity_revertIf_minAmountOutTooHigh() prank(user) public {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) amounts[i] = 1000 * 1e18;
        vm.expectRevert("Well: slippage");
        well.addLiquidity(amounts, 2001*1e27, user); // lpAmountOut is 2000*1e27
    }

    /// @dev addLiquidity -> removeLiquidity: zero hysteresis
    function test_addAndRemoveLiquidity() prank(user) public {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) amounts[i] = 1000 * 1e18;
        uint lpAmountOut = 2000 * 1e27;

        // addLiquidity
        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts, lpAmountOut);
        well.addLiquidity(amounts, lpAmountOut, user);

        assertEq(well.balanceOf(user), lpAmountOut);
        assertEq(tokens[0].balanceOf(user), 0, "incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user), 0, "incorrect token1 user amt");
        assertEq(tokens[0].balanceOf(address(well)), 2000 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 2000 * 1e18, "incorrect token1 well amt");

        // removeLiquidity
        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(lpAmountOut, amounts);
        well.removeLiquidity(lpAmountOut, amounts, user);

        assertEq(well.balanceOf(user), 0, "incorrect well user amt");
        assertEq(tokens[0].balanceOf(user), amounts[0],"incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user), amounts[1], "incorrect token1 user amt");
        assertEq(tokens[0].balanceOf(address(well)), 1000 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 1000 * 1e18, "incorrect token1 well amt");
    }

    /// @dev addLiquidity: adding zero liquidity emits empty event but doesn't change reserves
    function test_addLiquidity_zeroChange() prank(user) public {
        uint[] memory amounts = new uint[](tokens.length);
        uint liquidity = 0;

        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts, liquidity);
        well.addLiquidity(amounts, liquidity, user);

        assertEq(well.balanceOf(user), 0, "incorrect well user amt");
        assertEq(tokens[0].balanceOf(user), 1000 * 1e18,"incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user), 1000 * 1e18, "incorrect token1 user amt");
        assertEq(tokens[0].balanceOf(address(well)), 1000 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 1000 * 1e18, "incorrect token1 well amt");
    }

    /// @dev addLiquidity: two-token fuzzed
    function testFuzz_addLiquidity(uint x, uint y) prank(user) public {
        // amounts to add as liquidity
        uint[] memory amounts = new uint[](2);
        amounts[0] = bound(x, 0, 1000e18);
        amounts[1] = bound(y, 0, 1000e18);

        // expected new reserves after above amounts are added
        uint[] memory reserves = new uint[](2);
        reserves[0] = amounts[0] + tokens[0].balanceOf(address(well));
        reserves[1] = amounts[1] + tokens[1].balanceOf(address(well));

        // calculate new LP tokens delivered to user
        Call memory _function = well.wellFunction();
        uint newLpTokenSupply = IWellFunction(_function.target).calcLpTokenSupply(reserves, _function.data);
        uint totalSupply = well.totalSupply(); 
        uint lpAmountOut = newLpTokenSupply - totalSupply;
        
        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts, lpAmountOut);
        well.addLiquidity(amounts, 0, user);

        assertEq(well.balanceOf(user), lpAmountOut,"incorrect well user amt");
        assertEq(tokens[0].balanceOf(user), 1000e18 - amounts[0],"incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user), 1000e18 - amounts[1], "incorrect token1 user amt");
        assertEq(tokens[0].balanceOf(address(well)), 1000e18 + amounts[0], "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 1000e18 + amounts[1], "incorrect token1 well amt");
    }
}
