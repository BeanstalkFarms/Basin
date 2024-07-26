// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, Balances, ConstantProduct2, IERC20, Stable2} from "test/TestHelper.sol";
import {IWell} from "src/interfaces/IWell.sol";
import {IWellErrors} from "src/interfaces/IWellErrors.sol";

contract WellStable2ShiftTest is TestHelper {
    event Shift(uint256[] reserves, IERC20 toToken, uint256 minAmountOut, address recipient);

    function setUp() public {
        setupStable2Well();
    }

    /// @dev Shift excess token0 into token1.
    function testFuzz_shift(uint256 amount) public prank(user) {
        amount = bound(amount, 1, 1000e18);

        // Transfer `amount` of token0 to the Well
        tokens[0].transfer(address(well), amount);
        Balances memory wellBalanceBeforeShift = getBalances(address(well), well);
        assertEq(wellBalanceBeforeShift.tokens[0], 1000e18 + amount, "Well should have received token0");
        assertEq(wellBalanceBeforeShift.tokens[1], 1000e18, "Well should have NOT have received token1");

        // Get a user with a fresh address (no ERC20 tokens)
        address _user = users.getNextUserAddress();
        Balances memory userBalanceBeforeShift = getBalances(_user, well);

        // Verify that `_user` has no tokens
        assertEq(userBalanceBeforeShift.tokens[0], 0, "User should start with 0 of token0");
        assertEq(userBalanceBeforeShift.tokens[1], 0, "User should start with 0 of token1");

        uint256 minAmountOut = well.getShiftOut(tokens[1]);
        uint256[] memory calcReservesAfter = new uint256[](2);
        calcReservesAfter[0] = tokens[0].balanceOf(address(well));
        calcReservesAfter[1] = tokens[1].balanceOf(address(well)) - minAmountOut;

        vm.expectEmit(true, true, true, true);
        emit Shift(calcReservesAfter, tokens[1], minAmountOut, _user);
        uint256 amtOut = well.shift(tokens[1], minAmountOut, _user);

        uint256[] memory reserves = well.getReserves();
        Balances memory userBalanceAfterShift = getBalances(_user, well);
        Balances memory wellBalanceAfterShift = getBalances(address(well), well);

        // User should have gained token1
        assertEq(userBalanceAfterShift.tokens[0], 0, "User should NOT have gained token0");
        assertEq(userBalanceAfterShift.tokens[1], amtOut, "User should have gained token1");
        assertTrue(userBalanceAfterShift.tokens[1] >= userBalanceBeforeShift.tokens[1], "User should have more token1");

        // Reserves should now match balances
        assertEq(wellBalanceAfterShift.tokens[0], reserves[0], "Well should have correct token0 balance");
        assertEq(wellBalanceAfterShift.tokens[1], reserves[1], "Well should have correct token1 balance");

        // The difference has been sent to _user.
        assertEq(
            userBalanceAfterShift.tokens[1],
            wellBalanceBeforeShift.tokens[1] - wellBalanceAfterShift.tokens[1],
            "User should have correct token1 balance"
        );
        assertEq(
            userBalanceAfterShift.tokens[1],
            userBalanceBeforeShift.tokens[1] + amtOut,
            "User should have correct token1 balance"
        );
        checkStableSwapInvariant(address(well));
    }

    /// @dev Shift excess token0 into token0 (just transfers the excess token0 to the user).
    function testFuzz_shift_tokenOut(uint256 amount) public prank(user) {
        amount = bound(amount, 1, 1000e18);

        // Transfer `amount` of token0 to the Well
        tokens[0].transfer(address(well), amount);
        Balances memory wellBalanceBeforeShift = getBalances(address(well), well);
        assertEq(wellBalanceBeforeShift.tokens[0], 1000e18 + amount, "Well should have received tokens");

        // Get a user with a fresh address (no ERC20 tokens)
        address _user = users.getNextUserAddress();
        Balances memory userBalanceBeforeShift = getBalances(_user, well);

        // Verify that the user has no tokens
        assertEq(userBalanceBeforeShift.tokens[0], 0, "User should start with 0 of token0");
        assertEq(userBalanceBeforeShift.tokens[1], 0, "User should start with 0 of token1");

        uint256 minAmountOut = well.getShiftOut(tokens[0]);
        uint256[] memory calcReservesAfter = new uint256[](2);
        calcReservesAfter[0] = tokens[0].balanceOf(address(well)) - minAmountOut;
        calcReservesAfter[1] = tokens[1].balanceOf(address(well));

        vm.expectEmit(true, true, true, true);
        emit Shift(calcReservesAfter, tokens[0], minAmountOut, _user);
        // Shift the imbalanced token as the token out
        well.shift(tokens[0], 0, _user);

        uint256[] memory reserves = well.getReserves();
        Balances memory userBalanceAfterShift = getBalances(_user, well);
        Balances memory wellBalanceAfterShift = getBalances(address(well), well);

        // User should have gained token0
        assertEq(userBalanceAfterShift.tokens[0], amount, "User should have gained token0");
        assertEq(
            userBalanceAfterShift.tokens[1], userBalanceBeforeShift.tokens[1], "User should NOT have gained token1"
        );

        // Reserves should now match balances
        assertEq(wellBalanceAfterShift.tokens[0], reserves[0], "Well should have correct token0 balance");
        assertEq(wellBalanceAfterShift.tokens[1], reserves[1], "Well should have correct token1 balance");

        assertEq(
            userBalanceAfterShift.tokens[0],
            userBalanceBeforeShift.tokens[0] + amount,
            "User should have gained token 1"
        );
        checkInvariant(address(well));
    }

    /// @dev Calling shift() on a balanced Well should do nothing.
    function test_shift_balanced_pool() public prank(user) {
        Balances memory wellBalanceBeforeShift = getBalances(address(well), well);
        assertEq(wellBalanceBeforeShift.tokens[0], wellBalanceBeforeShift.tokens[1], "Well should should be balanced");

        // Get a user with a fresh address (no ERC20 tokens)
        address _user = users.getNextUserAddress();
        Balances memory userBalanceBeforeShift = getBalances(_user, well);

        // Verify that the user has no tokens
        assertEq(userBalanceBeforeShift.tokens[0], 0, "User should start with 0 of token0");
        assertEq(userBalanceBeforeShift.tokens[1], 0, "User should start with 0 of token1");

        well.shift(tokens[1], 0, _user);

        uint256[] memory reserves = well.getReserves();
        Balances memory userBalanceAfterShift = getBalances(_user, well);
        Balances memory wellBalanceAfterShift = getBalances(address(well), well);

        // User should have gained neither token
        assertEq(userBalanceAfterShift.tokens[0], 0, "User should NOT have gained token0");
        assertEq(userBalanceAfterShift.tokens[1], 0, "User should NOT have gained token1");

        // Reserves should equal balances
        assertEq(wellBalanceAfterShift.tokens[0], reserves[0], "Well should have correct token0 balance");
        assertEq(wellBalanceAfterShift.tokens[1], reserves[1], "Well should have correct token1 balance");
        checkInvariant(address(well));
    }

    function test_shift_fail_slippage(uint256 amount) public prank(user) {
        amount = bound(amount, 1, 1000e18);

        // Transfer `amount` of token0 to the Well
        tokens[0].transfer(address(well), amount);
        Balances memory wellBalanceBeforeShift = getBalances(address(well), well);
        assertEq(wellBalanceBeforeShift.tokens[0], 1000e18 + amount, "Well should have received token0");
        assertEq(wellBalanceBeforeShift.tokens[1], 1000e18, "Well should have NOT have received token1");

        uint256 amountOut = well.getShiftOut(tokens[1]);
        vm.expectRevert(abi.encodeWithSelector(IWellErrors.SlippageOut.selector, amountOut, type(uint256).max));
        well.shift(tokens[1], type(uint256).max, user);
    }
}
