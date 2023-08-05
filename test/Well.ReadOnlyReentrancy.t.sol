// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20, Well, Strings} from "test/TestHelper.sol";
import {SwapHelper} from "test/SwapHelper.sol";
import {ReentrantMockToken} from "mocks/tokens/ReentrantMockToken.sol";
import {IWell} from "src/interfaces/IWell.sol";

contract WellReadOnlyReentrancyTest is SwapHelper {
    using Strings for uint256;

    ReentrantMockToken[] _tokens;
    uint256[] amounts;

    function setUp() public {
        uint256 _numberOfTokens = 2;
        _tokens = new ReentrantMockToken[](_numberOfTokens);
        tokens = new IERC20[](_numberOfTokens);
        for (uint256 i; i < _numberOfTokens; i++) {
            _tokens[i] = new ReentrantMockToken(
                string.concat("Token ", i.toString()), // name
                string.concat("TOKEN", i.toString()), // symbol
                18 // decimals
            );
            tokens[i] = IERC20(_tokens[i]);
        }
        setupWell(deployWellFunction(), deployPumps(1), tokens);

        amounts = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }
    }

    function _checkReadOnlyReentrancy() internal {
        vm.expectRevert("ReentrancyGuard: reentrant call");
        well.addLiquidity(amounts, 0, user, type(uint256).max);
    }

    function test_readOnlyReentrancy_getReserves() public prank(user) {
        _tokens[0].setCall(address(well), abi.encode(IWell.getReserves.selector));
        _checkReadOnlyReentrancy();
    }

    function test_readOnlyReentrancy_getSwapOut() public prank(user) {
        _tokens[0].setCall(
            address(well), abi.encodeWithSelector(IWell.getSwapOut.selector, tokens[0], tokens[1], amounts[0])
        );
        _checkReadOnlyReentrancy();
    }

    function test_readOnlyReentrancy_getSwapIn() public prank(user) {
        _tokens[0].setCall(
            address(well), abi.encodeWithSelector(IWell.getSwapIn.selector, tokens[0], tokens[1], amounts[0])
        );
        _checkReadOnlyReentrancy();
    }

    function test_readOnlyReentrancy_getAddLiquidityOut() public prank(user) {
        _tokens[0].setCall(address(well), abi.encodeWithSelector(IWell.getAddLiquidityOut.selector, amounts));
        _checkReadOnlyReentrancy();
    }

    function test_readOnlyReentrancy_getRemoveLiquidityOut() public prank(user) {
        _tokens[0].setCall(address(well), abi.encodeWithSelector(IWell.getRemoveLiquidityOut.selector, amounts[0]));
        _checkReadOnlyReentrancy();
    }

    function test_readOnlyReentrancy_getRemoveLiquidityOneTokenOut() public prank(user) {
        _tokens[0].setCall(
            address(well), abi.encodeWithSelector(IWell.getRemoveLiquidityOneTokenOut.selector, amounts[0], tokens[0])
        );
        _checkReadOnlyReentrancy();
    }

    function test_readOnlyReentrancy_getRemoveLiquidityImbalancedIn() public prank(user) {
        _tokens[0].setCall(
            address(well), abi.encodeWithSelector(IWell.getRemoveLiquidityImbalancedIn.selector, amounts)
        );
        _checkReadOnlyReentrancy();
    }

    function test_readOnlyReentrancy_getShiftOut() public prank(user) {
        _tokens[0].setCall(address(well), abi.encodeWithSelector(IWell.getShiftOut.selector, tokens[0]));
        _checkReadOnlyReentrancy();
    }

    function test_readOnlyReentrancy_getSyncOut() public prank(user) {
        _tokens[0].setCall(address(well), abi.encode(IWell.getSyncOut.selector));
        _checkReadOnlyReentrancy();
    }
}
