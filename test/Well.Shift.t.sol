// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, Balances, ConstantProduct2, console, IERC20} from "test/TestHelper.sol";

contract WellShiftTest is TestHelper {
    ConstantProduct2 cp;
    bytes constant data = "";

    event Shift(uint[] reserves, IERC20 toToken, uint minAmountOut, address recipient);

    function setUp() public {
        cp = new ConstantProduct2();
        setupWell(2);
    }

    /// @dev Shift excess token0 into token1.
    function testFuzz_shift(uint amount) public prank(user) {
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

        well.sync();
        uint minAmountOut = well.getShiftOut(tokens[1]);
        uint[] memory calcReservesAfter = new uint[](2);
        calcReservesAfter[0] = well.getReserves()[0];
        calcReservesAfter[1] = well.getReserves()[1] - minAmountOut;

        vm.expectEmit(true, true, true, true);
        emit Shift(calcReservesAfter, tokens[1], minAmountOut, _user);
        uint amtOut = well.shift(tokens[1], minAmountOut, _user);

        uint[] memory reserves = well.getReserves();
        Balances memory userBalanceAfterShift = getBalances(_user, well);
        Balances memory wellBalanceAfterShift = getBalances(address(well), well);

        // User should have gained token1
        assertEq(userBalanceAfterShift.tokens[0], 0, "User should NOT have gained token0");
        assertEq(userBalanceAfterShift.tokens[1], amtOut, "User should have gained token1");
        assertTrue(userBalanceAfterShift.tokens[1] > userBalanceBeforeShift.tokens[1], "User should have more token1");

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
    }

    /// @dev Shift excess token0 into token0 (just transfers the excess token0 to the user).
    function testFuzz_shift_tokenOut(uint amount) public prank(user) {
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

        well.sync();
        uint minAmountOut = well.getShiftOut(tokens[0]);
        uint[] memory calcReservesAfter = new uint[](2);
        calcReservesAfter[0] = well.getReserves()[0] - minAmountOut;
        calcReservesAfter[1] = well.getReserves()[1];

        vm.expectEmit(true, true, true, true);
        emit Shift(calcReservesAfter, tokens[0], minAmountOut, _user);
        // Shift the imbalanced token as the token out
        well.shift(tokens[0], 0, _user);

        uint[] memory reserves = well.getReserves();
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

        uint[] memory reserves = well.getReserves();
        Balances memory userBalanceAfterShift = getBalances(_user, well);
        Balances memory wellBalanceAfterShift = getBalances(address(well), well);

        // User should have gained neither token
        assertEq(userBalanceAfterShift.tokens[0], 0, "User should NOT have gained token0");
        assertEq(userBalanceAfterShift.tokens[1], 0, "User should NOT have gained token1");

        // Reserves should equal balances
        assertEq(wellBalanceAfterShift.tokens[0], reserves[0], "Well should have correct token0 balance");
        assertEq(wellBalanceAfterShift.tokens[1], reserves[1], "Well should have correct token1 balance");
    }

    function test_shift_fail_slippage(uint amount) public prank(user) {
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

        vm.expectRevert("Well: slippage");
        uint amtOut = well.shift(tokens[1], type(uint).max, _user);
    }
}
