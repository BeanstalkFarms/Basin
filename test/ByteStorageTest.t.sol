/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";

import "src/utils/ByteStorage.sol";

contract LibByteStorageTest is TestHelper, ByteStorage {

    bytes32 constant BALANCES_STORAGE_SLOT = keccak256("balances.storage.slot");

    function testLibByteStorage(
        uint numberOfBalances,
        uint128[8] memory _balances
    ) public {

        vm.assume(numberOfBalances <= 8);

        uint[] memory balances = new uint[](_balances.length);

        for (uint i = 0; i < _balances.length; i++)
            balances[i] = _balances[i];

        storeUint128(BALANCES_STORAGE_SLOT, balances);
        uint[] memory balances2 = readUint128(BALANCES_STORAGE_SLOT, 2);

        for (uint i = 0; i < balances2.length; i++)
            assertEq(balances[i], balances2[i]);
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
