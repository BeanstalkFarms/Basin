/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";

contract WellInfoTest is TestHelper {

    event AddLiquidity(uint[] amounts);

    function setUp() public {
        setupWell(2);
    }

    function testGetWellAddressFromHash() external {
        address wellAddress = wellBuilder.getWellAddressFromHash(well.wellHash());
        assertEq(address(well), wellAddress);
    }

    function testGetWellAddressFromWellInfo() external {
        address wellAddress = wellBuilder.getWellAddress(w);
        assertEq(address(well), wellAddress);
    }

    function testGetWellHash() external {
        bytes32 wellHash = wellBuilder.getWellHash(w);
        assertEq(wellHash, well.wellHash());
    }
}
