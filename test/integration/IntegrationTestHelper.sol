// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console, stdError} from "forge-std/Test.sol";
import {Strings} from "oz/utils/Strings.sol";

import {MockToken} from "mocks/tokens/MockToken.sol";
import {MockPump} from "mocks/pumps/MockPump.sol";

import {Users} from "test/helpers/Users.sol";

import {Well, Call, IERC20} from "src/Well.sol";
import {Auger} from "src/Auger.sol";
import {Aquifer} from "src/Aquifer.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";

/// @dev helper struct for quickly loading user / well token balances
struct Balances {
    uint[] tokens;
    uint lp;
    uint lpSupply;
}

abstract contract IntegrationTestHelper is Test {
    using Strings for uint;

    // Users
    Users users;
    address user;
    address user2;

    // Primary well
    Well well;
    Call wellFunction; // Instantated during {deployWell}
    Call[] pumps; // Instantiated during upstream test

    // Factory / Registry
    Auger auger;
    Aquifer aquifer;

    function setupWell(IERC20[] memory _tokens) internal {
        Call[] memory _pumps = new Call[](0);
        setupWell(_tokens, Call(address(new ConstantProduct2()), new bytes(0)), _pumps);
    }

    function setupWell(IERC20[] memory _tokens, Call memory _function, Call[] memory _pumps) internal {
        wellFunction = _function;
        for (uint i = 0; i < _pumps.length; i++) {
            pumps.push(_pumps[i]);
        }

        initUser();

        // FIXME: manual name/symbol
        auger = new Auger();
        well = Well(auger.bore("TOKEN0:TOKEN1 Constant Product Well", "TOKEN0TOKEN1CPw", _tokens, _function, _pumps));

        // Mint mock tokens to user
        mintTokens(_tokens, user, 1000 * 1e18);
        mintTokens(_tokens, user2, 1000 * 1e18);
        approveMaxTokens(_tokens, user, address(well));
        approveMaxTokens(_tokens, user2, address(well));

        // Mint mock tokens to TestHelper
        mintTokens(_tokens, address(this), 1000 * 1e18);
        approveMaxTokens(_tokens, address(this), address(well));

        // Add initial liquidity from TestHelper
        addLiquidityEqualAmount(_tokens, address(this), 1000 * 1e18);
    }

    function initUser() internal {
        users = new Users();
        address[] memory _user = new address[](2);
        _user = users.createUsers(2);
        user = _user[0];
        user2 = _user[1];
    }

    /// @dev mint mock tokens to each recipient
    function mintTokens(IERC20[] memory _tokens, address recipient, uint amount) internal {
        for (uint i = 0; i < _tokens.length; i++) {
            deal(address(_tokens[i]), recipient, amount);
        }
    }

    /// @dev approve `spender` to use `owner` tokens
    function approveMaxTokens(IERC20[] memory _tokens, address owner, address spender) internal prank(owner) {
        for (uint i = 0; i < _tokens.length; i++) {
            _tokens[i].approve(spender, type(uint).max);
        }
    }

    /// @dev add the same `amount` of liquidity for all underlying tokens
    function addLiquidityEqualAmount(IERC20[] memory _tokens, address from, uint amount) internal prank(from) {
        uint[] memory amounts = new uint[](_tokens.length);
        for (uint i = 0; i < _tokens.length; i++) {
            amounts[i] = amount;
        }
        well.addLiquidity(amounts, 0, from);
    }

    /// @dev get `account` balance of each token, lp token, total lp token supply
    function getBalances(IERC20[] memory _tokens, address account) internal view returns (Balances memory balances) {
        uint[] memory tokenBalances = new uint[](_tokens.length);
        for (uint i = 0; i < tokenBalances.length; ++i) {
            tokenBalances[i] = _tokens[i].balanceOf(account);
        }
        balances = Balances(tokenBalances, well.balanceOf(account), well.totalSupply());
    }

    /// @dev impersonate `from`
    modifier prank(address from) {
        vm.startPrank(from);
        _;
        vm.stopPrank();
    }
}
