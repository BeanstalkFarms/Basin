/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";
import "src/wellFunctions/ConstantProduct.sol";

contract ConstantProductTest is TestHelper {
    ConstantProduct _function;
    bytes data = "";

    function setUp() public {
        _function = new ConstantProduct();
    }

    function testName() public {
        assertEq(_function.name(), "Constant Product");
        assertEq(_function.symbol(), "CP");
    }

    //////////// LP TOKEN SUPPLY ////////////

    /// @dev getLpTokenSupply: 0 balances = 0 supply
    function testLpTokenSupplyEmpty(uint n) public {
        vm.assume(n < 16);
        vm.assume(n >= 2);
        uint[] memory balances = new uint[](n);
        for(uint i = 0; i < n; ++i) 
            balances[i] = 0;
        assertEq(_function.getLpTokenSupply(balances, data), 0);
    }

    /// @dev getLpTokenSupply: `n` equal balances should summate with the token supply
    function testLpTokenSupplySmall(uint n) public {
        vm.assume(n < 16);
        vm.assume(n >= 2);
        uint[] memory balances = new uint[](n);
        for(uint i = 0; i < n; ++i) 
            balances[i] = 1;
        assertEq(_function.getLpTokenSupply(balances, data), 1 * n);
    }

    // function _getNBalances(uint n, uint v) internal returns (uint[] memory balances) {
    //     uint[] memory balances = new uint[](n);
    //     for(uint i = 0; i < n; ++i) 
    //         balances[i] = v;
    // }

}