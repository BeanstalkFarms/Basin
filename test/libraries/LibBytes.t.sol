// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper} from "test/TestHelper.sol";

import {LibBytes} from "src/libraries/LibBytes.sol";

contract LibBytesTest is TestHelper {
    uint constant NUM_RESERVES_MAX = 8;
    bytes32 constant RESERVES_STORAGE_SLOT = keccak256("reserves.storage.slot") - 1;

    /// @dev Store fuzzed reserves, re-read and compare.
    function testFuzz_storeAndRead(uint n, uint128[8] memory _reserves) public {
        vm.assume(n <= NUM_RESERVES_MAX);

        // Use the first `n` reserves. Cast uint128 reserves -> uint256
        uint[] memory reserves = new uint[](n);
        for (uint i = 0; i < n; i++) {
            reserves[i] = uint(_reserves[i]);
        }
        LibBytes.storeUint128(RESERVES_STORAGE_SLOT, reserves);

        // Re-read reserves and compare
        uint[] memory reserves2 = LibBytes.readUint128(RESERVES_STORAGE_SLOT, n);
        for (uint i = 0; i < reserves2.length; i++) {
            assertEq(reserves2[i], reserves[i], "ByteStorage: reserves mismatch");
        }
    }

    /// @dev Test every size of reserves array and every position for overflow
    /// All reserves besides `reserves[j]` are zero.
    function test_storeUint128_overflow() public {
        for (uint n = 1; n < NUM_RESERVES_MAX; ++n) {
            for (uint j = 0; j < n; ++j) {
                //
                uint[] memory reserves = new uint[](n);
                reserves[j] = uint(type(uint128).max) + 10;
                vm.expectRevert("ByteStorage: too large");
                LibBytes.storeUint128(RESERVES_STORAGE_SLOT, reserves);
            }
        }
    }

    /// @dev Fuzz test different sizes of reserves array and different positions
    /// for overflow. reserves besides `reserves[j]` can be non-zero.
    function testFuzz_storeUint128_overflow(uint n, uint tooLargeIndex, uint128[8] memory _reserves) public {
        vm.assume(n <= NUM_RESERVES_MAX);
        vm.assume(n > 0);
        vm.assume(tooLargeIndex < n);

        // Use the first `n` reserves. Cast uint128 reserves -> uint256
        uint[] memory reserves = new uint[](n);
        for (uint i = 0; i < n; i++) {
            reserves[i] = uint(_reserves[i]);
        }

        // Bump the reserve at `tooLargeIndex` outside the uin128 range
        reserves[tooLargeIndex] += uint(type(uint128).max) + 10;

        // Storage write should revert
        vm.expectRevert("ByteStorage: too large");
        LibBytes.storeUint128(RESERVES_STORAGE_SLOT, reserves);
    }

    function test_exploitStoreAndRead() public {
        // Write to storage slot to demonstrate overwriting existing values
        // In this case, 420 will be stored in the lower 128 bits of the last slot
        bytes32 slot = RESERVES_STORAGE_SLOT;
        uint maxI = (NUM_RESERVES_MAX - 1) / 2;
        uint storeValue = 420;
        assembly {
            sstore(add(slot, mul(maxI, 32)), shl(128, storeValue))
        }

        // Read reserves and assert the final reserve is 420
        uint[] memory reservesBefore = LibBytes.readUint128(RESERVES_STORAGE_SLOT, NUM_RESERVES_MAX);
        emit log_named_array("reservesBefore", reservesBefore);
        // Set up reserves to store, but only up to NUM_RESERVES_MAX - 1 as we have already stored a value in the last 128 bits of the last slot
        uint[] memory reserves = new uint[](NUM_RESERVES_MAX - 1);
        for (uint i = 1; i < NUM_RESERVES_MAX; i++) {
            reserves[i - 1] = i;
        }
        // Log the last reserve before the store, perhaps from other implementations which don't always act on the entire reserves length
        uint t;
        assembly {
            t := shr(128, sload(add(slot, mul(maxI, 32))))
        }
        emit log_named_uint("final slot, lower 128 bits before", t);
        // Store reserves
        LibBytes.storeUint128(RESERVES_STORAGE_SLOT, reserves);
        // Re-read reserves and compare
        uint[] memory reserves2 = LibBytes.readUint128(RESERVES_STORAGE_SLOT, NUM_RESERVES_MAX);

        emit log_named_array("reserves", reserves);
        emit log_named_array("reserves2", reserves2);

        // But wait, what about the last reserve
        assembly {
            t := shr(128, sload(add(slot, mul(maxI, 32))))
        }

        // Turns out it was overwritten by the last store as it calculates the sload incorrectly
        emit log_named_uint("final slot, lower 128 bits after", t);
        assertEq(t, 420, "Overwrote final slot");
    }
}
