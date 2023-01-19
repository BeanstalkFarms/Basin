/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";

import "src/utils/ByteStorage.sol";

contract ByteStorageTest is TestHelper, ByteStorage {

    bytes32 constant BALANCES_STORAGE_SLOT = keccak256("balances.storage.slot");

    /// @dev 
    function test_libByteStorage(
        uint n,
        uint128[8] memory _balances
    ) public {
        vm.assume(n <= 8);
        vm.assume(_balances[0] >= 0);
        vm.assume(_balances[1] >= 0);

        console.log("n", n);

        // Use the first `n` balances.
        // Cast uint128 balances -> uint256.
        uint[] memory balances = new uint[](_balances.length);
        for (uint i = 0; i < n; i++) {
            console.log("balance", i, _balances[i]);
            balances[i] = uint(_balances[i]);
        }

        // Store balances, then re-read
        storeUint128(BALANCES_STORAGE_SLOT, balances);
        uint[] memory balances2 = readUint128(BALANCES_STORAGE_SLOT, n); //balances.length);

        for (uint i = 0; i < balances2.length; i++) {
            console.log("assert index", i, balances[i], balances2[i]);
            assertEq(balances[i], balances2[i]);
        }
    }

    function testTooLargeLibByteStorageFuzz(
        uint numberOfBalances,
        uint tooLargeIndex,
        uint128[8] memory _balances
    ) public {

        vm.assume(numberOfBalances <= 8);
        vm.assume(tooLargeIndex < numberOfBalances);

        uint[] memory balances = new uint[](_balances.length);

        for (uint i = 0; i < _balances.length; i++)
            balances[i] = _balances[i];

        balances[tooLargeIndex] += uint(type(uint128).max)+1;

        console.log(balances[tooLargeIndex]);

        vm.expectRevert("ByteStorage: too large");
        storeUint128(BALANCES_STORAGE_SLOT, balances);
    }

    function testTooLargeLibByteStorage() public {
        for (uint i = 1; i < 8; ++i) {
            for (uint j = 0; j < i; ++j) {
                uint[] memory balances = new uint[](i);
                balances[j] = uint(type(uint128).max) + 1;
                vm.expectRevert("ByteStorage: too large");
                storeUint128(BALANCES_STORAGE_SLOT, balances);
            }
        }
    }
}
