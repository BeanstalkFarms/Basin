// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "test/TestHelper.sol";

import {LibLastReserveBytes} from "src/libraries/LibLastReserveBytes.sol";

contract LibLastReserveBytesTest is TestHelper {
    using LibLastReserveBytes for bytes32;

    uint256 constant NUM_RESERVES_MAX = 8;
    bytes32 constant RESERVES_STORAGE_SLOT = bytes32(uint256(keccak256("reserves.storage.slot")) - 1);

    /// @dev Store fuzzed reserves, re-read and compare.
    function testEmaFuzz_storeAndRead(
        uint8 n,
        uint40 lastTimestamp,
        bytes13[NUM_RESERVES_MAX] memory _reserves
    ) public {
        vm.assume(n <= NUM_RESERVES_MAX);

        // Use the first `n` reserves. Cast uint104 reserves -> uint256
        bytes16[] memory reserves = new bytes16[](n);
        for (uint256 i; i < n; i++) {
            reserves[i] = bytes16(_reserves[i]) << 24;
        }
        RESERVES_STORAGE_SLOT.storeLastReserves(lastTimestamp, reserves);

        // Re-read reserves and compare
        (uint8 _n, uint40 _lastTimestamp, bytes16[] memory reserves2) = RESERVES_STORAGE_SLOT.readLastReserves();
        uint8 __n = RESERVES_STORAGE_SLOT.readNumberOfReserves();
        assertEq(__n, n, "ByteStorage: n mismatch");
        assertEq(_n, n, "ByteStorage: n mismatch");
        assertEq(_lastTimestamp, lastTimestamp, "ByteStorage: lastTimestamp mismatch");
        for (uint256 i; i < reserves2.length; i++) {
            assertEq(reserves2[i], reserves[i], "ByteStorage: reserves mismatch");
        }
    }
}
