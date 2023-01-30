/**
 * SPDX-License-Identifier: MIT
 *
 */
pragma solidity ^0.8.17;

import "test/TestHelper.sol";

import {LibLastReserveBytes} from "src/libraries/LibLastReserveBytes.sol";

contract LibEmaBytesTest is TestHelper {
    using LibLastReserveBytes for bytes32;

    uint constant NUM_RESERVES_MAX = 4;
    bytes32 constant RESERVES_STORAGE_SLOT = keccak256("reserves.storage.slot");

    /// @dev Store fuzzed reserves, re-read and compare.
    function testEmaFuzz_storeAndRead(uint8 n, uint40 lastTimestamp, uint104[8] memory _reserves) public {
        vm.assume(n <= NUM_RESERVES_MAX);
        vm.assume(n > 1);

        // Use the first `n` reserves. Cast uint104 reserves -> uint256
        uint[] memory reserves = new uint[](n);
        for (uint i = 0; i < n; i++) {
            reserves[i] = uint(_reserves[i]);
        }
        RESERVES_STORAGE_SLOT.storeLastReserves(lastTimestamp, reserves);
        // Re-read reserves and compare
        (uint8 _n, uint40 _lastTimestamp, uint[] memory reserves2) = RESERVES_STORAGE_SLOT.readLastReserves();
        uint8 __n = RESERVES_STORAGE_SLOT.readN();
        assertEq(__n, n, "ByteStorage: n mismatch");
        assertEq(_n, n, "ByteStorage: n mismatch");
        assertEq(_lastTimestamp, lastTimestamp, "ByteStorage: lastTimestamp mismatch");
        for (uint i = 0; i < reserves2.length; i++) {
            assertEq(reserves2[i], reserves[i], "ByteStorage: reserves mismatch");
        }
    }
}
