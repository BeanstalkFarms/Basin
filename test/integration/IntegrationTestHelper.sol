// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console, stdError} from "forge-std/Test.sol";
import {Users} from "test/helpers/Users.sol";
import {TestHelper, Balances} from "test/TestHelper.sol";

import {Well, Call, IERC20} from "src/Well.sol";
import {Auger} from "src/Auger.sol";
import {Aquifer} from "src/Aquifer.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";
import {LibContractInfo} from "src/libraries/LibContractInfo.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";

abstract contract IntegrationTestHelper is TestHelper {
    using LibContractInfo for address;

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

        auger = new Auger();
        Aquifer aquifer = new Aquifer();

        well = Well(aquifer.boreWell(_tokens, wellFunction, pumps, auger));

        // Mint mock tokens to user
        mintTokens(_tokens, user, initialLiquidity);
        mintTokens(_tokens, user2, initialLiquidity);

        approveMaxTokens(_tokens, user, address(well));
        approveMaxTokens(_tokens, user2, address(well));

        // Mint mock tokens to TestHelper
        mintTokens(_tokens, address(this), initialLiquidity * 5);
        approveMaxTokens(_tokens, address(this), address(well));

        // Add initial liquidity from TestHelper
        addLiquidityEqualAmount(_tokens, address(this), initialLiquidity);
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
}
