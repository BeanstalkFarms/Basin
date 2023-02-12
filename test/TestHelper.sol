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

abstract contract TestHelper is Test {
    using Strings for uint;

    // Users
    Users users;
    address user;
    address user2;

    // Primary well
    Well well;
    address wellImplementation;
    IERC20[] tokens; // Mock token addresses sorted lexicographically
    Call wellFunction; // Instantated during {deployWell}
    Call[] pumps; // Instantiated during upstream test
    bytes wellData;

    // Factory / Registry
    Aquifer aquifer;

    // initial liquidity amount given to users and wells
    uint public constant initialLiquidity = 1000 * 1e18;

    function setupWell(uint n) internal {
        Call[] memory _pumps = new Call[](0);
        setupWell(n, Call(address(new ConstantProduct2()), new bytes(0)), _pumps);
    }

    function setupWell(uint n, Call memory _function, Call[] memory _pumps) internal {
        wellFunction = _function;
        for (uint i = 0; i < _pumps.length; i++) {
            pumps.push(_pumps[i]);
        }

        initUser();
        deployMockTokens(n);

        // FIXME: manual name/symbol
        // FIXME: use aquifer
        well = new Well("TOKEN0:TOKEN1 Constant Product Well", "TOKEN0TOKEN1CPw", tokens, _function, _pumps);

        // Mint mock tokens to user
        mintTokens(user, initialLiquidity);
        mintTokens(user2, initialLiquidity);
        approveMaxTokens(user, address(well));
        approveMaxTokens(user2, address(well));

        // Mint mock tokens to TestHelper
        mintTokens(address(this), initialLiquidity);
        approveMaxTokens(address(this), address(well));

        // Add initial liquidity from TestHelper
        addLiquidityEqualAmount(address(this), initialLiquidity);
    }

    function initUser() internal {
        users = new Users();
        address[] memory _user = new address[](2);
        _user = users.createUsers(2);
        user = _user[0];
        user2 = _user[1];
    }

    /// @dev deploy `n` mock ERC20 tokens and sort by address
    function deployMockTokens(uint n) internal {
        IERC20[] memory _tokens = new IERC20[](n);
        for (uint i = 0; i < n; i++) {
            IERC20 temp = IERC20(
                new MockToken(
                    string.concat("Token ", i.toString()), // name
                    string.concat("TOKEN", i.toString()), // symbol
                    18 // decimals
                )
            );
            // Insertion sort
            uint j;
            if (i > 0) {
                for (j = i; j >= 1 && temp < _tokens[j - 1]; j--) {
                    _tokens[j] = _tokens[j - 1];
                }
                _tokens[j] = temp;
            } else {
                _tokens[0] = temp;
            }
        }
        for (uint i = 0; i < n; i++) {
            tokens.push(_tokens[i]);
        }
    }

    /// @dev mint mock tokens to each recipient
    function mintTokens(address recipient, uint amount) internal {
        for (uint i = 0; i < tokens.length; i++) {
            MockToken(address(tokens[i])).mint(recipient, amount);
        }
    }

    function deployWellImplementation() internal {
        wellImplementation = address(new Well(
            new string(0),
            new string(0),
            new IERC20[](0),
            Call(address(0), new bytes(0)),
            new Call[](0)
        ));
    }

    /// @dev approve `spender` to use `owner` tokens
    function approveMaxTokens(address owner, address spender) internal prank(owner) {
        for (uint i = 0; i < tokens.length; i++) {
            tokens[i].approve(spender, type(uint).max);
        }
    }

    /// @dev add the same `amount` of liquidity for all underlying tokens
    function addLiquidityEqualAmount(address from, uint amount) internal prank(from) {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = amount;
        }
        well.addLiquidity(amounts, 0, from);
    }

    /// @dev gets the first `n` mock tokens
    function getTokens(uint n) internal view returns (IERC20[] memory _tokens) {
        _tokens = new IERC20[](n);
        for (uint i; i < n; ++i) {
            _tokens[i] = tokens[i];
        }
    }

    /// @dev get `account` balance of each token, lp token, total lp token supply
    function getBalances(address account, Well _well) internal view returns (Balances memory balances) {
        uint[] memory tokenBalances = new uint[](tokens.length);
        for (uint i = 0; i < tokenBalances.length; ++i) {
            tokenBalances[i] = tokens[i].balanceOf(account);
        }
        balances = Balances(tokenBalances, _well.balanceOf(account), _well.totalSupply());
    }

    /// @dev impersonate `from`
    modifier prank(address from) {
        vm.startPrank(from);
        _;
        vm.stopPrank();
    }
}
