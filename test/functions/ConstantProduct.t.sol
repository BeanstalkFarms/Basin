/**
 * SPDX-License-Identifier: MIT
 *
 */
pragma solidity ^0.8.17;

import {WellFunctionHelper} from "./WellFunctionHelper.sol";
import {ConstantProduct} from "src/functions/ConstantProduct.sol";

contract ConstantProductTest is WellFunctionHelper {
    function setUp() public {
        _function = new ConstantProduct();
        _data = "";
    }

    function test_name() public {
        assertEq(_function.name(), "Constant Product");
        assertEq(_function.symbol(), "CP");
    }

    //////////// LP TOKEN SUPPLY ////////////

    /// @dev calcLpTokenSupply: `n` equal reserves should summate with the token supply
    function testLpTokenSupplySmall(uint n) public {
        vm.assume(n < 16);
        vm.assume(n >= 2);
        uint[] memory reserves = new uint[](n);
        for (uint i = 0; i < n; ++i) {
            reserves[i] = 1;
        }
        assertEq(_function.calcLpTokenSupply(reserves, _data), 1 * n);
    }
}
