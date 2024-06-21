// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
    function testLpTokenSupplySmall(uint256 n) public {
        n = bound(n, 2, 15);
        uint256[] memory reserves = new uint256[](n);
        for (uint256 i; i < n; ++i) {
            reserves[i] = 1;
        }
        assertEq(_function.calcLpTokenSupply(reserves, _data), 1 * n);
    }
}
