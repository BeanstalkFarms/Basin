/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";

import "src/utils/ByteStorage.sol";

contract ByteStorageTest is TestHelper, ByteStorage {

    uint256 constant MAX_BALANCES = 8;
    bytes32 constant BALANCES_STORAGE_SLOT = keccak256("balances.storage.slot");

    /// @dev Store fuzzed balances, re-read and compare.
    function testFuzz_storeAndRead(
        uint numBalances,
        uint128[8] memory _balances
    ) public {
        vm.assume(numBalances <= MAX_BALANCES);

        // Use the first `n` balances. Cast uint128 balances -> uint256
        uint[] memory balances = new uint[](numBalances);
        for (uint i = 0; i < numBalances; i++) {
            balances[i] = uint(_balances[i]);
        }
        storeUint128(BALANCES_STORAGE_SLOT, balances);

        // Re-read balances and compare
        uint[] memory balances2 = readUint128(BALANCES_STORAGE_SLOT, numBalances);
        for (uint i = 0; i < balances2.length; i++) {
            assertEq(balances2[i], balances[i], "ByteStorage: balances mismatch");
        }
    }

    /// @dev Test every size of balances array and every position for overflow
    /// All balances besides `balances[j]` are zero.
    function test_storeUint128_overflow() public {
        for (uint numBalances = 1; numBalances < MAX_BALANCES; ++numBalances) {
            for (uint j = 0; j < numBalances; ++j) {
                // 
                uint[] memory balances = new uint[](numBalances);
                balances[j] = uint(type(uint128).max) + 10;
                vm.expectRevert("ByteStorage: too large");
                storeUint128(BALANCES_STORAGE_SLOT, balances);
            }
        }
    }

    /// @dev Fuzz test different sizes of balances array and different positions
    /// for overflow. Balances besides `balances[j]` can be non-zero.
    function testFuzz_storeUint128_overflow(
        uint numBalances,
        uint tooLargeIndex,
        uint128[8] memory _balances
    ) public {
        vm.assume(numBalances <= MAX_BALANCES);
        vm.assume(numBalances > 0);
        vm.assume(tooLargeIndex < numBalances);

        // Use the first `n` balances. Cast uint128 balances -> uint256
        uint[] memory balances = new uint[](numBalances);
        for (uint i = 0; i < _balances.length; i++)
            balances[i] = uint(_balances[i]);

        // Bump the balance at `tooLargeIndex` outside the uin128 range
        balances[tooLargeIndex] += uint(type(uint128).max) + 10;

        // Storage write should revert
        vm.expectRevert("ByteStorage: too large");
        storeUint128(BALANCES_STORAGE_SLOT, balances);
    }
}
