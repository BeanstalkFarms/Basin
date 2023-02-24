// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console, stdError} from "forge-std/Test.sol";
import {Strings} from "oz/utils/Strings.sol";

import {MockToken} from "mocks/tokens/MockToken.sol";
import {MockTokenFeeOnTransfer} from "mocks/tokens/MockTokenFeeOnTransfer.sol";
import {MockPump} from "mocks/pumps/MockPump.sol";

import {Users} from "test/helpers/Users.sol";

import {Well, Call, IERC20} from "src/Well.sol";
import {Aquifer} from "src/Aquifer.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";

import {WellDeployer} from "script/helpers/WellDeployer.sol";

/// @dev helper struct for quickly loading user / well token balances
struct Balances {
    uint[] tokens;
    uint lp;
    uint lpSupply;
}

abstract contract TestHelper is Test, WellDeployer {
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
        Call memory _wellFunction = Call(address(new ConstantProduct2()), new bytes(0));
        Call[] memory _pumps = new Call[](2);
        _pumps[0].target = address(new MockPump());
        _pumps[0].data = new bytes(1);
        _pumps[1].target = address(new MockPump());
        _pumps[1].data = new bytes(1);
        setupWell(n, _wellFunction, _pumps);
    }

    function setupWell(uint n, Call memory _wellFunction, Call[] memory _pumps) internal {
        wellFunction = _wellFunction;
        for (uint i = 0; i < _pumps.length; i++) {
            pumps.push(_pumps[i]);
        }

        initUser();
        deployMockTokens(n);

        deployWellImplementation();
        aquifer = new Aquifer();
        well = encodeAndBoreWell(
            address(aquifer),
            wellImplementation,
            tokens,
            _wellFunction,
            _pumps,
            bytes32(0)
        );

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

    ////////// Test Tokens

    /// @dev deploy `n` mock ERC20 tokens and sort by address
    function deployMockTokens(uint n) internal {
        for (uint i = 0; i < n; i++) {
            IERC20 temp = IERC20(
                new MockToken(
                    string.concat("Token ", i.toString()), // name
                    string.concat("TOKEN", i.toString()), // symbol
                    18 // decimals
                )
            );
            tokens.push(temp);
        }
    }

    /// @dev deploy `n` mock ERC20 tokens and sort by address
    function deployMockTokensFeeOnTransfer(uint n) internal {
        for (uint i = 0; i < n; i++) {
            IERC20 temp = IERC20(
                new MockTokenFeeOnTransfer(
                    string.concat("Token ", i.toString()), // name
                    string.concat("TOKEN", i.toString()), // symbol
                    18 // decimals
                )
            );
            tokens.push(temp);
        }
    }

    /// @dev mint mock tokens to each recipient
    function mintTokens(address recipient, uint amount) internal {
        for (uint i = 0; i < tokens.length; i++) {
            MockToken(address(tokens[i])).mint(recipient, amount);
        }
    }

    /// @dev approve `spender` to use `owner` tokens
    function approveMaxTokens(address owner, address spender) internal prank(owner) {
        for (uint i = 0; i < tokens.length; i++) {
            tokens[i].approve(spender, type(uint).max);
        }
    }

    /// @dev gets the first `n` mock tokens
    function getTokens(uint n) internal view returns (IERC20[] memory _tokens) {
        _tokens = new IERC20[](n);
        for (uint i; i < n; ++i) {
            _tokens[i] = tokens[i];
        }
    }

    ////////// Well Setup

    /// @dev deploy the Well contract
    function deployWellImplementation() internal {
        wellImplementation = address(new Well());
    }

    /// @dev add the same `amount` of liquidity for all underlying tokens
    function addLiquidityEqualAmount(address from, uint amount) internal prank(from) {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = amount;
        }
        well.addLiquidity(amounts, 0, from);
    }

    ////////// Balance Helpers

    /// @dev get `account` balance of each token, lp token, total lp token supply
    function getBalances(address account, Well _well) internal view returns (Balances memory balances) {
        uint[] memory tokenBalances = new uint[](tokens.length);
        for (uint i = 0; i < tokenBalances.length; ++i) {
            tokenBalances[i] = tokens[i].balanceOf(account);
        }
        balances = Balances(tokenBalances, _well.balanceOf(account), _well.totalSupply());
    }


    ////////// EVM Helpers

    function increaseTime(uint _seconds) internal {
        vm.warp(block.timestamp + _seconds);
    }

    /// @dev impersonate `from`
    modifier prank(address from) {
        vm.startPrank(from);
        _;
        vm.stopPrank();
    }

    
    ////////// Assertions

    function assertEq(IERC20 a, IERC20 b, string memory err) internal {
        assertEq(address(a), address(b), err);
    }

    function assertEq(IERC20[] memory a, IERC20[] memory b, string memory err) internal {
        assertEq(a.length, b.length, err);
        for (uint i = 0; i < a.length; i++) {
            assertEq(a[i], b[i], err); // uses the prev overload
        }
    }

    function assertEq(Call memory a, Call memory b, string memory err) internal {
        assertEq(a.target, b.target, err);
        assertEq(a.data, b.data, err);
    }

    function assertEq(Call[] memory a, Call[] memory b, string memory err) internal {
        assertEq(a.length, b.length, err);
        for (uint i = 0; i < a.length; i++) {
            assertEq(a[i], b[i], err); // uses the prev overload
        }
    }
}
