// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, Balances, ConstantProduct2, console } from "test/TestHelper.sol";

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
        

        assertEq(wellBalanceBeforeShift.tokens[0], 1000e18 + amounts, "Well should have received tokens");

        uint[] memory reserves = new uint[](2);
        reserves[0] = wellBalanceBeforeShift.tokens[0];
        reserves[1] = wellBalanceBeforeShift.tokens[1];

        // Get a user with a fresh address (no ERC20 tokens)
        address _user = users.getNextUserAddress();

        // Verify that the user has no tokens
        Balances memory userBalanceBeforeShift = getBalances(_user, well);

        uint amtOut = well.shift(
            _user,
            tokens[1],
            0
        );

        reserves = well.getReserves();

        Balances memory userBalanceAfterShift = getBalances(_user, well);
        Balances memory wellBalanceAfterShift = getBalances(address(well), well);

        // TODO: should we make sure that the well has the actual, or correct reserves?
        // uint calcToken0ReservesAfter = cp.calcReserve(reserves, 0, wellBalanceBeforeShift.lpSupply, data);
        // uint calcToken1ReservesAfter = cp.calcReserve(reserves, 1, wellBalanceBeforeShift.lpSupply, data);

        // assertEq(reserves[0], calcToken0ReservesAfter, "updated reserve does not match calculated reserve");
        // assertEq(reserves[1], calcToken1ReservesAfter, "updated reserve does not match calculated reserve");


        assertEq(userBalanceAfterShift.tokens[1], amtOut, "User should have gained token 1");
        assertEq(userBalanceAfterShift.tokens[0], 0, "User should have not gained token 2");

        assertEq(wellBalanceAfterShift.tokens[0], reserves[0], "Well should have correct token 1 balance");
        assertEq(wellBalanceAfterShift.tokens[1], reserves[1], "Well should have correct token 2 balance");

        assertTrue(userBalanceAfterShift.tokens[1] > userBalanceBeforeShift.tokens[1], "User should have more token 0");
        
        // The difference has been sent to _user.
        assertEq(userBalanceAfterShift.tokens[1], wellBalanceBeforeShift.tokens[1] - wellBalanceAfterShift.tokens[1], "User should have correct token 2 balance");
        assertEq(userBalanceAfterShift.tokens[1], userBalanceBeforeShift.tokens[1] + amtOut, "User should have correct token 1 balance");
    }
}
