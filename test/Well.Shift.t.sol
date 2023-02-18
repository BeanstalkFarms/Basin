// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, Balances, ConstantProduct2} from "test/TestHelper.sol";

contract WellShiftTest is TestHelper {
    ConstantProduct2 cp;
    bytes constant data = "";

    function setUp() public {
        cp = new ConstantProduct2();
        setupWell(2);
    }

    function test_initialized() public {
        // Well should have liquidity
        Balances memory wellBalance = getBalances(address(well), well);
        assertEq(wellBalance.tokens[0], 1000e18);
        assertEq(wellBalance.tokens[1], 1000e18);
    }

    function testFuzz_shift(uint[2] calldata amounts) public prank(user) {
        vm.assume(amounts[0] <= 1000e18 && amounts[0] > 0);
        vm.assume(amounts[1] <= 1000e18 && amounts[1] > 0);

        tokens[0].transfer(address(well), amounts[0]);
        tokens[1].transfer(address(well), amounts[1]);

        Balances memory wellBalanceBeforeShift = getBalances(address(well), well);
        // Verify that the Well has received the tokens
        assertEq(wellBalanceBeforeShift.tokens[0], 1000e18 + amounts[0]);
        assertEq(wellBalanceBeforeShift.tokens[1], 1000e18 + amounts[1]);

        uint[] memory reserves = new uint[](2);
        reserves[0] = wellBalanceBeforeShift.tokens[0];
        reserves[1] = wellBalanceBeforeShift.tokens[1];

        // Get a user with a fresh address (no ERC20 tokens)
        address _user = users.getNextUserAddress();

        // Verify that the user has no tokens
        Balances memory userBalanceBeforeShift = getBalances(_user, well);
        assertEq(userBalanceBeforeShift.tokens[0], 0);
        assertEq(userBalanceBeforeShift.tokens[1], 0);

        well.shift(_user);

        uint calcToken0ReservesAfter = cp.calcReserve(reserves, 0, wellBalanceBeforeShift.lpSupply, data);
        uint calcToken1ReservesAfter = cp.calcReserve(reserves, 1, wellBalanceBeforeShift.lpSupply, data);

        Balances memory userBalanceAfterShift = getBalances(_user, well);
        Balances memory wellBalanceAfterShift = getBalances(address(well), well);

        assertEq(wellBalanceAfterShift.tokens[0], calcToken0ReservesAfter);
        assertEq(wellBalanceAfterShift.tokens[1], calcToken1ReservesAfter);

        assertTrue(userBalanceAfterShift.tokens[0] > userBalanceBeforeShift.tokens[0]);
        assertTrue(userBalanceAfterShift.tokens[1] > userBalanceBeforeShift.tokens[1]);
        // The difference has been sent to _user.
        assertEq(userBalanceAfterShift.tokens[0], wellBalanceBeforeShift.tokens[0] - calcToken0ReservesAfter);
        assertEq(userBalanceAfterShift.tokens[1], wellBalanceBeforeShift.tokens[1] - calcToken1ReservesAfter);
    }
}
