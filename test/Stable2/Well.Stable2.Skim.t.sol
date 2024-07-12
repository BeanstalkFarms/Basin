// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, Balances} from "test/TestHelper.sol";

contract WellStable2SkimTest is TestHelper {
    function setUp() public {
        setupStable2Well();
    }

    function test_initialized() public {
        // Well should have liquidity
        Balances memory wellBalance = getBalances(address(well), well);
        assertEq(wellBalance.tokens[0], 1000e18);
        assertEq(wellBalance.tokens[1], 1000e18);
    }

    function testFuzz_skim(uint256[2] calldata amounts) public prank(user) {
        vm.assume(amounts[0] <= 800e18);
        vm.assume(amounts[1] <= 800e18);

        // Transfer from Test contract to Well
        tokens[0].transfer(address(well), amounts[0]);
        tokens[1].transfer(address(well), amounts[1]);

        Balances memory wellBalanceBeforeSkim = getBalances(address(well), well);
        // Verify that the Well has received the tokens
        assertEq(wellBalanceBeforeSkim.tokens[0], 1000e18 + amounts[0]);
        assertEq(wellBalanceBeforeSkim.tokens[1], 1000e18 + amounts[1]);

        // Get a user with a fresh address (no ERC20 tokens)
        address _user = users.getNextUserAddress();
        uint256[] memory reserves = new uint256[](2);

        // Verify that the user has no tokens
        Balances memory userBalanceBeforeSkim = getBalances(_user, well);
        reserves[0] = userBalanceBeforeSkim.tokens[0];
        reserves[1] = userBalanceBeforeSkim.tokens[1];
        assertEq(reserves[0], 0);
        assertEq(reserves[1], 0);

        well.skim(_user);

        Balances memory userBalanceAfterSkim = getBalances(_user, well);
        Balances memory wellBalanceAfterSkim = getBalances(address(well), well);

        // Since only 1000e18 of each token was added as liquidity, the Well's reserve
        // should be reset back to this.
        assertEq(wellBalanceAfterSkim.tokens[0], 1000e18);
        assertEq(wellBalanceAfterSkim.tokens[1], 1000e18);

        // The difference has been sent to _user.
        assertEq(userBalanceAfterSkim.tokens[0], amounts[0]);
        assertEq(userBalanceAfterSkim.tokens[1], amounts[1]);
    }
}
