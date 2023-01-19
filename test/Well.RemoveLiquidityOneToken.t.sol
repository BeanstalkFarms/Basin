/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";

contract WellRemoveLiquidityOneTokenTest is TestHelper {
    ConstantProduct2 cp;
    bytes constant data = "";

    event RemoveLiquidityOneToken(
        uint lpAmountIn,
        IERC20 tokenOut,
        uint tokenAmountOut
    );

    function setUp() public {
        cp = new ConstantProduct2();
        setupWell(2);

        // Add liquidity. `user` now has (2 * 1000 * 1e27) LP tokens
        addLiquidityEqualAmount(user, 1000 * 1e18);
    }

    /// @dev Assumes use of ConstantProduct2
    function test_getRemoveLiquidityOneTokenOut() public {
        uint amountOut = well.getRemoveLiquidityOneTokenOut(tokens[0], 1000 * 1e27);
        assertEq(amountOut, 875 * 1e18, "incorrect tokenOut");
    }

    /// @dev Base case
    function test_removeLiquidityOneToken() prank(user) public {
        uint lpAmountIn = 1000 * 1e27;
        uint minTokenAmountOut = 875 * 1e18;

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidityOneToken(lpAmountIn, tokens[0], minTokenAmountOut);

        uint amountOut = well.removeLiquidityOneToken(lpAmountIn, tokens[0], minTokenAmountOut, user);

        assertEq(well.balanceOf(user), lpAmountIn, "Incorrect lpAmountIn");

        assertEq(tokens[0].balanceOf(user), amountOut, "Incorrect token0 user balance");
        assertEq(tokens[1].balanceOf(user), 0, "Incorrect token1 user balance");

        assertEq(tokens[0].balanceOf(address(well)), 1125 * 1e18, "Incorrect token0 well balance");
        assertEq(tokens[1].balanceOf(address(well)), 2000 * 1e18, "Incorrect token1 well balance");
    }

    /// @dev not enough tokens received for `lpAmountIn`.
    function test_removeLiquidityOneToken_revertIf_amountOutTooLow() prank(user) public {
        uint lpAmountIn = 1000 * 1e18;
        uint minTokenAmountOut = 876 * 1e18;
        vm.expectRevert("Well: slippage");
        well.removeLiquidityOneToken(lpAmountIn, tokens[0], minTokenAmountOut, user);
    }

    /// @dev Fuzz test: EQUAL token balances, IMBALANCED removal
    /// The Well contains equal balances of all underlying tokens before execution.
    function testFuzz_removeLiquidityOneToken(uint a0) prank(user) public {    
        // Assume we're removing tokens[0]
        uint[] memory amounts = new uint[](2);
        amounts[0] = bound(a0, 1e6, 750e18); 
        amounts[1] = 0;

        uint userLpBalance = well.balanceOf(user);
        
        // Find the LP amount that should be burned given the fuzzed
        // amounts. Works even though only amounts[0] is set.
        uint lpAmountIn = well.getRemoveLiquidityImbalancedIn(amounts);
        
        // Calculate change in Well balances after removing liquidity
        uint[] memory balances = new uint[](2);
        balances[0] = tokens[0].balanceOf(address(well)) - amounts[0];
        balances[1] = tokens[1].balanceOf(address(well)) - amounts[1]; // should stay the same

        // Calculate the new LP token supply after the Well's balances are changed.
        // The delta `lpAmountBurned` is the amount of LP that should be burned
        // when this liquidity is removed.
        uint newLpTokenSupply =  cp.getLpTokenSupply(balances, data);
        uint lpAmountBurned = well.totalSupply() - newLpTokenSupply;

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidityOneToken(lpAmountBurned, tokens[0], amounts[0]);
        well.removeLiquidityOneToken(lpAmountIn, tokens[0], 0, user); // no minimum out

        assertEq(well.balanceOf(user), userLpBalance - lpAmountIn, "Incorrect lp output");
        assertEq(tokens[0].balanceOf(user), amounts[0], "Incorrect token0 user balance");
        assertEq(tokens[1].balanceOf(user), amounts[1], "Incorrect token1 user balance"); // should stay the same
        assertEq(tokens[0].balanceOf(address(well)), 2000e18 - amounts[0], "Incorrect token0 well balance");
        assertEq(tokens[1].balanceOf(address(well)), 2000e18 - amounts[1], "Incorrect token1 well balance"); // should stay the same  
    }

    // TODO: fuzz test: imbalanced ratio of tokens
}
