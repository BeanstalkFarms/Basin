// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ABDKMathQuad} from "src/libraries/ABDKMathQuad.sol";

/**
 * @title LibLastReserveBytes
 * @author Brendan
 * @notice  Contains byte operations used during storage reads & writes for Pumps.
 *
 * @dev {LibLastReserveBytes} tightly packs a `uint8 n`, `uint40 timestamp` and `bytes16[] reserves`
 * for gas efficiency purposes. The first 2 values in `reserves` are packed into the first slot with
 * `timestamp` and `n`. Thus, only the first 13 bytes (104 bit) of each reserve value are stored and
 * the last 3 bytes get truncated. Given that the Well uses the quadruple-precision floating-point
 * format for last reserve values and only uses the last reserves to compute the max increase/decrease
 * in reserves for manipulation resistance purposes, the gas savings is worth the lose of precision.
 */
library LibLastReserveBytes {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    function readNumberOfReserves(bytes32 slot) internal view returns (uint8 _numberOfReserves) {
        assembly {
            _numberOfReserves := shr(248, sload(slot))
        }
    }

    function storeLastReserves(bytes32 slot, uint40 lastTimestamp, uint256[] memory lastReserves) internal {
        // Potential optimization – shift reserve bytes left to perserve extra decimal precision.
        uint8 n = uint8(lastReserves.length);

        bytes16[] memory reserves = new bytes16[](n);

        for (uint256 i; i < n; ++i) {
            reserves[i] = lastReserves[i].fromUInt();
        }

        if (n == 1) {
            assembly {
                sstore(slot, or(or(shl(208, lastTimestamp), shl(248, n)), shl(104, shr(152, mload(add(reserves, 32))))))
            }
            return;
        }
        assembly {
            sstore(
                slot,
                or(
                    or(shl(208, lastTimestamp), shl(248, n)),
                    or(shl(104, shr(152, mload(add(reserves, 32)))), shr(152, mload(add(reserves, 64))))
                )
            )
            // slot := add(slot, 32)
        }
        if (n > 2) {
            uint256 maxI = n / 2; // number of fully-packed slots
            uint256 iByte; // byte offset of the current reserve
            for (uint256 i = 1; i < maxI; ++i) {
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
            // Equivalent to "reserves.length % 2 == 1" but cheaper.
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
     * @dev Read `n` packed bytes16 reserves at storage position `slot`.
     */
    function readLastReserves(
        bytes32 slot
    ) internal view returns (uint8 n, uint40 lastTimestamp, uint256[] memory lastReserves) {
        // Shortcut: two reserves can be quickly unpacked from one slot
        bytes32 temp;
        assembly {
            temp := sload(slot)
            n := shr(248, temp)
            lastTimestamp := shr(208, temp)
        }
        if (n == 0) return (n, lastTimestamp, lastReserves);
        // Initialize array with length `n`, fill it in via assembly
        bytes16[] memory reserves = new bytes16[](n);
        assembly {
            mstore(add(reserves, 32), shl(152, shr(104, temp)))
        }
        if (n == 1) {
            lastReserves = new uint256[](1);
            lastReserves[0] = reserves[0].toUInt();
            return (n, lastTimestamp, lastReserves);
        }
        assembly {
            mstore(add(reserves, 64), shl(152, temp))
        }

        if (n > 2) {
            uint256 iByte;
            for (uint256 i = 3; i <= n; ++i) {
                // `iByte` is the byte position for the current slot:
                // i        3 4 5 6
                // iByte    1 1 2 2
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

        lastReserves = new uint256[](n);
        for (uint256 i; i < n; ++i) {
            lastReserves[i] = reserves[i].toUInt();
        }
    }

    function readBytes(bytes32 slot) internal view returns (bytes32 value) {
        assembly {
            value := sload(slot)
        }
    }
}
