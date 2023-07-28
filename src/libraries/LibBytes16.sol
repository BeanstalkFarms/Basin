// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title LibBytes16
 * @author Publius
 * @notice Contains byte operations used during storage reads & writes for Pumps.
 *
 * {LibBytes16} tightly packs an array of `bytes16` values into `n / 2` storage
 * slots, where `n` is number of items to pack.
 */
library LibBytes16 {
    /**
     * @dev Store packed bytes16 `reserves` starting at storage position `slot`.
     */
    function storeBytes16(bytes32 slot, bytes16[] memory reserves) internal {
        // Shortcut: two reserves can be packed into one slot without a loop
        if (reserves.length == 2) {
            assembly {
                sstore(slot, add(mload(add(reserves, 32)), shr(128, mload(add(reserves, 64)))))
            }
        } else {
            uint256 maxI = reserves.length / 2; // number of fully-packed slots
            uint256 iByte; // byte offset of the current reserve
            for (uint256 i; i < maxI; ++i) {
                iByte = i * 64;
                assembly {
                    sstore(
                        add(slot, i),
                        add(mload(add(reserves, add(iByte, 32))), shr(128, mload(add(reserves, add(iByte, 64)))))
                    )
                }
            }
            // If there is an odd number of reserves, create a slot with the last reserve
            // Since `i < maxI` above, the next byte offset `maxI * 64`
            // Equivalent to "i % 2 == 1", but cheaper.
            if (reserves.length & 1 == 1) {
                iByte = maxI * 64;
                assembly {
                    sstore(
                        add(slot, maxI),
                        add(mload(add(reserves, add(iByte, 32))), shr(128, shl(128, sload(add(slot, maxI)))))
                    )
                }
            }
        }
    }

    /**
     * @dev Read `n` packed uint128 reserves at storage position `slot`.
     */
    function readBytes16(bytes32 slot, uint256 n) internal view returns (bytes16[] memory reserves) {
        // Initialize array with length `n`, fill it in via assembly
        reserves = new bytes16[](n);

        // Shortcut: two reserves can be quickly unpacked from one slot
        if (n == 2) {
            assembly {
                mstore(add(reserves, 32), sload(slot))
                mstore(add(reserves, 64), shl(128, sload(slot)))
            }
            return reserves;
        }

        uint256 iByte;
        for (uint256 i = 1; i <= n; ++i) {
            // `iByte` is the byte position for the current slot:
            // i        1 2 3 4 5 6
            // iByte    0 0 1 1 2 2
            iByte = (i - 1) / 2;
            // Equivalent to "i % 2 == 1" but cheaper.
            if (i & 1 == 1) {
                assembly {
                    mstore(
                        // store at index i * 32; i = 0 is skipped by loop
                        add(reserves, mul(i, 32)),
                        sload(add(slot, iByte))
                    )
                }
            } else {
                assembly {
                    mstore(add(reserves, mul(i, 32)), shl(128, sload(add(slot, iByte))))
                }
            }
        }
    }
}
