/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "forge-std/console2.sol";
import "forge-std/console.sol";
import "forge-std/Test.sol";

import "oz/utils/Strings.sol";

import {Well, Call, IERC20} from "src/Well.sol";
import {Auger} from "src/Auger.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";

import {MockToken} from "mocks/tokens/MockToken.sol";
import {MockPump} from "mocks/pumps/MockPump.sol";

import {Users} from "utils/Users.sol";

abstract contract TestHelper is Test {
    using Strings for uint;

    address user;
    address user2;

    IERC20[] tokens; // Mock token addresses sorted lexicographically
    Call[] pumps; // Instantiated during upstream test
    Call wellFunction; // Instantated during {deployWell}
    Well well;

    function setupWell(uint n) internal {
        Call[] memory _pumps = new Call[](0);
        setupWell(
            n,
            Call(address(new ConstantProduct2()), new bytes(0)),
            _pumps
        );
    }

    function setupWell(uint n, Call memory _function, Call[] memory _pumps) internal {
        wellFunction = _function;
        for(uint i = 0; i < _pumps.length; i++)
            pumps.push(_pumps[i]);

        initUser();
        deployMockTokens(n);

        // FIXME: manual name/symbol
        well = new Well(
            tokens,
            _function,
            _pumps,
            "TOKEN0:TOKEN1 Constant Product Well",
            "TOKEN0TOKEN1CPw"
        );

        // Mint mock tokens to user
        mintTokens(user, 1000 * 1e18);
        mintTokens(user2,1000 * 1e18);
        approveMaxTokens(user, address(well));
<<<<<<< Updated upstream
        
        // Mint mock tokens to TestHelper
        mintTokens(address(this), 1000 * 1e18);
        approveMaxTokens(address(this), address(well));

        // Add initial liquidity from TestHelper
        addLiquidityEqualAmount(address(this), 1000 * 1e18);
=======
        approveMaxTokens(user2, address(well));
        addLiquidtyEqualAmount(address(this), 1000 * 1e18);
>>>>>>> Stashed changes
    }

    function initUser() internal {
        Users users = new Users();
        address[] memory _users = new address[](2);
        _users = users.createUsers(2);
        user = _users[0];
        user2 = _users[1];
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
                for (j = i; j >= 1 && temp < _tokens[j - 1]; j--)
                    _tokens[j] = _tokens[j - 1];
                _tokens[j] = temp;
            } else _tokens[0] = temp;
        }
        for (uint i = 0; i < n; i++) tokens.push(_tokens[i]);
    }

    /// @dev mint mock tokens to each recipient
    function mintTokens(address recipient, uint amount) internal {
        for (uint i = 0; i < tokens.length; i++)
            MockToken(address(tokens[i])).mint(recipient, amount);
    }

    /// @dev approve `spender` to use `owner` tokens
    function approveMaxTokens(address owner, address spender) prank(owner) internal {
        for (uint i = 0; i < tokens.length; i++)
            tokens[i].approve(spender, type(uint).max);
    }

    // function deployWell() internal returns (Well) {
    //     wellFunction = Call(address(new ConstantProduct2()), new bytes(0));
    //     well = Well(wellBuilder.buildWell(
    //         "TOKEN0:TOKEN1 Constant Product Well",
    //         "TOKEN0TOKEN1CPw",
    //         tokens,
    //         wellFunction,
    //         pump
    //     ));
    //     return well;
    // }

    /// @dev add the same `amount` of liquidity for all underlying tokens
    function addLiquidityEqualAmount(address from, uint amount) prank(from) internal {
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) amounts[i] = amount;
        well.addLiquidity(amounts, 0, from);
    }

    /// @dev gets the first `n` mock tokens
    function getTokens(uint n)
        internal
        view
        returns (IERC20[] memory _tokens)
    {
        _tokens = new IERC20[](n);
        for (uint i; i < n; ++i) {
            _tokens[i] = tokens[i];
        }
    }

    modifier prank(address from) {
        vm.startPrank(from);
        _;
        vm.stopPrank();
    }
}
