// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, Balances, ConstantProduct2, console} from "test/TestHelper.sol";

contract WellShiftTest is TestHelper {
    ConstantProduct2 cp;
    bytes constant data = "";

    function setUp() public {
        cp = new ConstantProduct2();
        setupWell(2);
    }

    function testFuzz_shift(uint amounts) public prank(user) {
        vm.assume(amounts <= 1000e18 && amounts > 0);

        tokens[0].transfer(address(well), amounts);
        Balances memory wellBalanceBeforeShift = getBalances(address(well), well);
        // Verify that the Well has received the tokens
        console.log("amounts:", amounts);

        console.log("balance 0:", wellBalanceBeforeShift.tokens[0]);
        console.log("balance 1:", wellBalanceBeforeShift.tokens[1]);

        uint[] memory __reserves = well.getReserves();
        console.log("reserves 0:", __reserves[0]);
        console.log("reserves 1:", __reserves[1]);

        assertEq(wellBalanceBeforeShift.tokens[0], 1000e18 + amounts, "Well should have received tokens");

        uint[] memory reserves = new uint[](2);
        reserves[0] = wellBalanceBeforeShift.tokens[0];
        reserves[1] = wellBalanceBeforeShift.tokens[1];

        // Get a user with a fresh address (no ERC20 tokens)
        address _user = users.getNextUserAddress();

        // Verify that the user has no tokens
        Balances memory userBalanceBeforeShift = getBalances(_user, well);

        uint amtOut = well.shift(tokens[1], 0, _user);

        reserves = well.getReserves();

        Balances memory userBalanceAfterShift = getBalances(_user, well);
        Balances memory wellBalanceAfterShift = getBalances(address(well), well);

        assertEq(userBalanceAfterShift.tokens[1], amtOut, "User should have gained token 1");
        assertEq(userBalanceAfterShift.tokens[0], 0, "User should have not gained token 2");

        assertEq(wellBalanceAfterShift.tokens[0], reserves[0], "Well should have correct token 1 balance");
        assertEq(wellBalanceAfterShift.tokens[1], reserves[1], "Well should have correct token 2 balance");

        assertTrue(userBalanceAfterShift.tokens[1] > userBalanceBeforeShift.tokens[1], "User should have more token 0");

        // The difference has been sent to _user.
        assertEq(
            userBalanceAfterShift.tokens[1],
            wellBalanceBeforeShift.tokens[1] - wellBalanceAfterShift.tokens[1],
            "User should have correct token 2 balance"
        );
        assertEq(
            userBalanceAfterShift.tokens[1],
            userBalanceBeforeShift.tokens[1] + amtOut,
            "User should have correct token 1 balance"
        );
    }

    function testFuzz_shift_tokenOut(uint amount) public prank(user) {
        vm.assume(amount <= 1000e18 && amount > 0);

        tokens[0].transfer(address(well), amount);
        Balances memory wellBalanceBeforeShift = getBalances(address(well), well);

        assertEq(wellBalanceBeforeShift.tokens[0], 1000e18 + amount, "Well should have received tokens");

        uint[] memory reserves = new uint[](2);
        reserves[0] = wellBalanceBeforeShift.tokens[0];
        reserves[1] = wellBalanceBeforeShift.tokens[1];

        // Get a user with a fresh address (no ERC20 tokens)
        address _user = users.getNextUserAddress();

        // Verify that the user has no tokens
        Balances memory userBalanceBeforeShift = getBalances(_user, well);

        // shift the imbalanced token as the token out
        well.shift(tokens[0], 0, _user);

        reserves = well.getReserves();

        Balances memory userBalanceAfterShift = getBalances(_user, well);
        Balances memory wellBalanceAfterShift = getBalances(address(well), well);

        assertEq(userBalanceAfterShift.tokens[0], amount, "User should  have gained token 1");
        assertEq(
            userBalanceAfterShift.tokens[1], userBalanceBeforeShift.tokens[1], "User should not have gained token 2"
        );

        assertEq(wellBalanceAfterShift.tokens[0], reserves[0], "Well should have correct token 1 balance");
        assertEq(wellBalanceAfterShift.tokens[1], reserves[1], "Well should have correct token 2 balance");

        assertEq(
            userBalanceAfterShift.tokens[0],
            userBalanceBeforeShift.tokens[0] + amount,
            "User should have gained token 1"
        );
    }

    function test_shift_balanced_pool() public prank(user) {
        Balances memory wellBalanceBeforeShift = getBalances(address(well), well);

        assertEq(wellBalanceBeforeShift.tokens[0], 1000e18, "Well should have correct token balance");
        assertEq(wellBalanceBeforeShift.tokens[1], 1000e18, "Well should have correct token balance");

        uint[] memory reserves = new uint[](2);
        reserves[0] = wellBalanceBeforeShift.tokens[0];
        reserves[1] = wellBalanceBeforeShift.tokens[1];

        // Get a user with a fresh address (no ERC20 tokens)
        address _user = users.getNextUserAddress();

        // Verify that the user has no tokens
        Balances memory userBalanceBeforeShift = getBalances(_user, well);

        well.shift(tokens[1], 0, _user);

        reserves = well.getReserves();

        Balances memory userBalanceAfterShift = getBalances(_user, well);
        Balances memory wellBalanceAfterShift = getBalances(address(well), well);

        assertEq(userBalanceAfterShift.tokens[1], 0, "User should have gained token 1");
        assertEq(userBalanceAfterShift.tokens[0], 0, "User should have not gained token 2");

        assertEq(wellBalanceAfterShift.tokens[0], reserves[0], "Well should have correct token 1 balance");
        assertEq(wellBalanceAfterShift.tokens[1], reserves[1], "Well should have correct token 2 balance");

        assertEq(userBalanceAfterShift.tokens[1], userBalanceBeforeShift.tokens[0], "User should have gained token 1");
        assertEq(
            userBalanceAfterShift.tokens[0], userBalanceBeforeShift.tokens[0], "User should have not gained token 2"
        );
    }
}
