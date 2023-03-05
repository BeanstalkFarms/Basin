// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {console, TestHelper, IERC20, Call, Balances} from "test/TestHelper.sol";
import {ConstantProduct2, IWellFunction} from "src/functions/ConstantProduct2.sol";

contract WellFailOnZeroReserve is TestHelper {
    event AddLiquidity(uint[] tokenAmountsIn, uint lpAmountOut, address recipient);
    event RemoveLiquidity(uint lpAmountIn, uint[] tokenAmountsOut, address recipient);

    function setUp() public {
        setupWell(2);
    }

    function test_remove_all_liquidity() public {
        uint[] memory amounts = new uint[](tokens.length);

        for (uint i = 0; i < tokens.length; i++) {
            amounts[i] = 1000 * 1e18;
        }

        uint totalSupply = well.totalSupply();

        vm.expectRevert("Well: Invalid reserve");
        well.removeLiquidity(totalSupply, amounts, user);
    }

}
