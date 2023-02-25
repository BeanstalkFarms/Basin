// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {TestHelper, IERC20, Call, Balances} from "test/TestHelper.sol";
import {ConstantProduct2, IWellFunction} from "src/functions/ConstantProduct2.sol";

contract WellAddLiquidityFeeOnTransferNoFeeTest is TestHelper {
    event AddLiquidity(uint[] tokenAmountsIn, uint lpAmountOut);
    event RemoveLiquidity(uint lpAmountIn, uint[] tokenAmountsOut);

    function setUp() public {
        setupWell(2);
    }

    /// @dev addLiquidity: equal amounts.
    function test_addLiquidity_equalAmounts_feeOnTransfer_noFee() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }
        uint lpAmountOut = 2000 * 1e27;

        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts, lpAmountOut);
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut, user);

        Balances memory userBalance = getBalances(user, well);
        Balances memory wellBalance = getBalances(address(well), well);

        assertEq(userBalance.lp, lpAmountOut);

        // Consumes all of user's tokens
        assertEq(userBalance.tokens[0], 0, "incorrect token0 user amt");
        assertEq(userBalance.tokens[1], 0, "incorrect token1 user amt");

        // Adds to the Well's reserves
        assertEq(wellBalance.tokens[0], initialLiquidity + amounts[0], "incorrect token0 well amt");
        assertEq(wellBalance.tokens[1], initialLiquidity + amounts[1], "incorrect token1 well amt");
    }

    /// @dev addLiquidity: one-sided.
    function test_addLiquidity_oneToken_feeOnTransfer_noFee() public prank(user) {
        uint[] memory amounts = new uint[](2);
        amounts[0] = 10 * 1e18;
        amounts[1] = 0;

        uint amountOut = 9_975_124_224_178_054_043_852_982_550;

        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts, amountOut);
        well.addLiquidityFeeOnTransfer(amounts, 0, user);

        Balances memory userBalance = getBalances(user, well);
        Balances memory wellBalance = getBalances(address(well), well);

        assertEq(userBalance.lp, amountOut, "incorrect well user balance");
        assertEq(userBalance.tokens[0], initialLiquidity - amounts[0], "incorrect token0 user amt");
        assertEq(userBalance.tokens[1], initialLiquidity, "incorrect token1 user amt");
        assertEq(wellBalance.tokens[0], initialLiquidity + amounts[0], "incorrect token0 well amt");
        assertEq(wellBalance.tokens[1], initialLiquidity, "incorrect token1 well amt");
    }

    /// @dev addLiquidity: reverts for slippage
    function test_addLiquidity_revertIf_minAmountOutTooHigh_feeOnTransfer_noFee() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }
        vm.expectRevert("Well: slippage");
        well.addLiquidityFeeOnTransfer(amounts, 2001 * 1e27, user); // lpAmountOut is 2000*1e27
    }

    /// @dev addLiquidity -> removeLiquidity: zero hysteresis
    function test_addAndRemoveLiquidity_feeOnTransfer_noFee() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }
        uint lpAmountOut = 2000 * 1e27;

        // addLiquidity
        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts, lpAmountOut);
        well.addLiquidityFeeOnTransfer(amounts, lpAmountOut, user);

        Balances memory userBalanceAddLiquidity = getBalances(user, well);
        Balances memory wellBalanceAddLiquidity = getBalances(address(well), well);

        assertEq(userBalanceAddLiquidity.lp, lpAmountOut);
        assertEq(userBalanceAddLiquidity.tokens[0], 0, "incorrect token0 user amt");
        assertEq(userBalanceAddLiquidity.tokens[1], 0, "incorrect token1 user amt");

        assertEq(wellBalanceAddLiquidity.tokens[0], initialLiquidity + amounts[0], "incorrect token0 well amt");
        assertEq(wellBalanceAddLiquidity.tokens[1], initialLiquidity + amounts[1], "incorrect token1 well amt");

        // removeLiquidity
        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(lpAmountOut, amounts);
        well.removeLiquidity(lpAmountOut, amounts, user);

        Balances memory userBalanceRemoveLiquidity = getBalances(user, well);
        Balances memory wellBalanceRemoveLiquidity = getBalances(address(well), well);

        assertEq(userBalanceRemoveLiquidity.lp, 0, "incorrect well user amt");
        assertEq(userBalanceRemoveLiquidity.tokens[0], amounts[0], "incorrect token0 user amt");
        assertEq(userBalanceRemoveLiquidity.tokens[1], amounts[1], "incorrect token1 user amt");

        // returns back to iniitialLiquidity as user has removed thier added liquidity from the pool
        assertEq(wellBalanceRemoveLiquidity.tokens[0], initialLiquidity, "incorrect token0 well amt");
        assertEq(wellBalanceRemoveLiquidity.tokens[1], initialLiquidity, "incorrect token1 well amt");
    }

    /// @dev addLiquidity: adding zero liquidity emits empty event but doesn't change reserves
    function test_addLiquidity_zeroChange_feeOnTransfer_noFee() public prank(user) {
        uint[] memory amounts = new uint[](tokens.length);
        uint liquidity = 0;

        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts, liquidity);
        well.addLiquidityFeeOnTransfer(amounts, liquidity, user);

        Balances memory userBalance = getBalances(user, well);
        Balances memory wellBalance = getBalances(address(well), well);

        assertEq(userBalance.lp, 0, "incorrect well user amt");
        assertEq(userBalance.tokens[0], initialLiquidity, "incorrect token0 user amt");
        assertEq(userBalance.tokens[1], initialLiquidity, "incorrect token1 user amt");
        assertEq(wellBalance.tokens[0], initialLiquidity, "incorrect token0 well amt");
        assertEq(wellBalance.tokens[1], initialLiquidity, "incorrect token1 well amt");
    }

    /// @dev addLiquidity: two-token fuzzed
    function testFuzz_addLiquidity_feeOnTransfer_noFee(uint x, uint y) public prank(user) {
        // amounts to add as liquidity
        uint[] memory amounts = new uint[](2);
        amounts[0] = bound(x, 0, 1000e18);
        amounts[1] = bound(y, 0, 1000e18);

        // expected new reserves after above amounts are added
        Balances memory wellBalanceBeforeAddLiquidity = getBalances(address(well), well);

        uint[] memory reserves = new uint[](2);
        reserves[0] = amounts[0] + wellBalanceBeforeAddLiquidity.tokens[0];
        reserves[1] = amounts[1] + wellBalanceBeforeAddLiquidity.tokens[1];

        // calculate new LP tokens delivered to user
        Call memory _function = well.wellFunction();
        uint newLpTokenSupply = IWellFunction(_function.target).calcLpTokenSupply(reserves, _function.data);
        uint totalSupply = well.totalSupply();
        uint lpAmountOut = newLpTokenSupply - totalSupply;

        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts, lpAmountOut);
        well.addLiquidityFeeOnTransfer(amounts, 0, user);

        Balances memory userBalanceAfterAddLiquidity = getBalances(user, well);
        Balances memory wellBalanceAfterAddLiquidity = getBalances(address(well), well);

        assertEq(userBalanceAfterAddLiquidity.lp, lpAmountOut, "incorrect well user amt");
        assertEq(userBalanceAfterAddLiquidity.tokens[0], initialLiquidity - amounts[0], "incorrect token0 user amt");
        assertEq(userBalanceAfterAddLiquidity.tokens[1], initialLiquidity - amounts[1], "incorrect token1 user amt");
        assertEq(wellBalanceAfterAddLiquidity.tokens[0], initialLiquidity + amounts[0], "incorrect token0 well amt");
        assertEq(wellBalanceAfterAddLiquidity.tokens[1], initialLiquidity + amounts[1], "incorrect token1 well amt");
    }
}