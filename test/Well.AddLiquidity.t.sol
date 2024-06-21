// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {TestHelper, IERC20, Call, Balances} from "test/TestHelper.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";
import {Snapshot, AddLiquidityAction, RemoveLiquidityAction, LiquidityHelper} from "test/LiquidityHelper.sol";

contract WellAddLiquidityTest is LiquidityHelper {
    function setUp() public {
        setupWell(2);
    }

    /// @dev Liquidity is initially added in {TestHelper}; ensure that subsequent
    /// tests will run correctly.
    function test_liquidityInitialized() public {
        IERC20[] memory tokens = well.tokens();
        Balances memory userBalance = getBalances(user, well);
        Balances memory wellBalance = getBalances(address(well), well);
        for (uint256 i; i < tokens.length; i++) {
            assertEq(userBalance.tokens[i], initialLiquidity, "incorrect user token reserve");
            assertEq(wellBalance.tokens[i], initialLiquidity, "incorrect well token reserve");
        }
    }

    /// @dev Adding liquidity in equal proportions should summate and be scaled
    /// up by sqrt(ConstantProduct2.EXP_PRECISION)
    function test_getAddLiquidityOut_equalAmounts() public {
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }
        uint256 lpAmountOut = well.getAddLiquidityOut(amounts);
        assertEq(lpAmountOut, 1000 * 1e24, "Incorrect AmountOut");
    }

    function test_getAddLiquidityOut_oneToken() public {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10 * 1e18;
        amounts[1] = 0;

        uint256 amountOut = well.getAddLiquidityOut(amounts);
        assertEq(amountOut, 4_987_562_112_089_027_021_926_491, "incorrect amt out");
    }

    function test_addLiquidity_revertIf_minAmountOutTooHigh() public prank(user) {
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }
        uint256 lpAmountOut = well.getAddLiquidityOut(amounts);

        vm.expectRevert(abi.encodeWithSelector(SlippageOut.selector, lpAmountOut, lpAmountOut + 1));
        well.addLiquidity(amounts, lpAmountOut + 1, user, type(uint256).max); // lpAmountOut is 2000*1e27
    }

    function test_addLiquidity_revertIf_expired() public {
        vm.expectRevert(Expired.selector);
        well.addLiquidity(new uint256[](tokens.length), 0, user, block.timestamp - 1);
    }

    function test_addLiquidity_balanced() public prank(user) {
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }
        uint256 lpAmountOut = 1000 * 1e24;

        vm.expectEmit(true, true, true, true);
        emit AddLiquidity(amounts, lpAmountOut, user);
        well.addLiquidity(amounts, lpAmountOut, user, type(uint256).max);

        Balances memory userBalance = getBalances(user, well);
        Balances memory wellBalance = getBalances(address(well), well);

        assertEq(userBalance.lp, lpAmountOut);

        // Consumes all of user's tokens
        assertEq(userBalance.tokens[0], 0, "incorrect token0 user amt");
        assertEq(userBalance.tokens[1], 0, "incorrect token1 user amt");

        // Adds to the Well's reserves
        assertEq(wellBalance.tokens[0], initialLiquidity + amounts[0], "incorrect token0 well amt");
        assertEq(wellBalance.tokens[1], initialLiquidity + amounts[1], "incorrect token1 well amt");
        checkInvariant(address(well));
    }

    function test_addLiquidity_oneSided() public prank(user) {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10 * 1e18;
        amounts[1] = 0;

        Snapshot memory before;
        AddLiquidityAction memory action;
        action.amounts = amounts;
        action.lpAmountOut = well.getAddLiquidityOut(amounts);
        action.recipient = user;
        action.fees = new uint256[](2);

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidity(amounts, well.getAddLiquidityOut(amounts), user, type(uint256).max);
        afterAddLiquidity(before, action);
        checkInvariant(address(well));
    }

    /// @dev Adding and removing liquidity in sequence should return the Well to its previous state
    function test_addAndRemoveLiquidity() public prank(user) {
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }
        uint256 lpAmountOut = 1000 * 1e24;

        Snapshot memory before;
        AddLiquidityAction memory action;
        action.amounts = amounts;
        action.lpAmountOut = well.getAddLiquidityOut(amounts);
        action.recipient = user;
        action.fees = new uint256[](2);

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidity(amounts, lpAmountOut, user, type(uint256).max);
        afterAddLiquidity(before, action);

        Snapshot memory beforeRemove;
        RemoveLiquidityAction memory actionRemove;
        actionRemove.lpAmountIn = well.getAddLiquidityOut(amounts);
        actionRemove.amounts = amounts;
        actionRemove.recipient = user;

        (beforeRemove, actionRemove) = beforeRemoveLiquidity(actionRemove);
        well.removeLiquidity(lpAmountOut, amounts, user, type(uint256).max);
        afterRemoveLiquidity(beforeRemove, actionRemove);
        checkInvariant(address(well));
    }

    /// @dev Adding zero liquidity emits empty event but doesn't change reserves
    function test_addLiquidity_zeroChange() public prank(user) {
        uint256[] memory amounts = new uint256[](tokens.length);
        uint256 liquidity = 0;

        Snapshot memory before;
        AddLiquidityAction memory action;
        action.amounts = amounts;
        action.lpAmountOut = liquidity;
        action.recipient = user;
        action.fees = new uint256[](2);

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidity(amounts, liquidity, user, type(uint256).max);
        afterAddLiquidity(before, action);
        checkInvariant(address(well));
    }

    /// @dev Two-token fuzz test adding liquidity in any ratio
    function testFuzz_addLiquidity(uint256 x, uint256 y) public prank(user) {
        // amounts to add as liquidity
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = bound(x, 0, type(uint104).max);
        amounts[1] = bound(y, 0, type(uint104).max);
        mintTokens(user, amounts);

        Snapshot memory before;
        AddLiquidityAction memory action;
        action.amounts = amounts;
        action.lpAmountOut = well.getAddLiquidityOut(amounts);
        action.recipient = user;
        action.fees = new uint256[](2);

        (before, action) = beforeAddLiquidity(action);
        well.addLiquidity(amounts, well.getAddLiquidityOut(amounts), user, type(uint256).max);
        afterAddLiquidity(before, action);
        checkInvariant(address(well));
    }
}
