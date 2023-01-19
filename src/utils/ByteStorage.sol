/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "forge-std/console.sol";

/**
 * @title ByteStorage provides an interface for storing bytes.
 * @author Publius
 */
contract ByteStorage {
    /**
     * @dev Store `balances` in storage at position `slot`.
     */
    function storeUint128(bytes32 slot, uint256[] memory balances) internal {
        // Shortcut: two balances can be cheaply packed into one slot
        if (balances.length == 2) {
            bytes16 temp;
            require(balances[0] <= type(uint128).max, "ByteStorage: too large");
            require(balances[1] <= type(uint128).max, "ByteStorage: too large");
            assembly {
                temp := mload(add(balances, 64))
                sstore(
                    slot,
                    add(
                        shl(128, mload(add(balances, 32))),
                        shr(128, shl(128, mload(add(balances, 64))))
                    )
                )
            }
        } else {
            uint256 maxI = balances.length / 2; // number of fully-packed slots
            uint256 iByte; // byte offset of the current balance
            for (uint i; i < maxI; ++i) {
                require(balances[2*i] <= type(uint128).max, "ByteStorage: too large");
                require(balances[2*i+1] <= type(uint128).max, "ByteStorage: too large");
                iByte = i * 64;
                assembly {
                    sstore(
                        add(slot, mul(i, 32)),
                        add(
                            shl(128, mload(add(balances, add(iByte, 32)))),
                            shr(
                                128,
                                shl(128, mload(add(balances, add(iByte, 64))))
                            )
                        )
                    )
                }
            }
            // If there is an odd number of balances, create a slot with the last balance
            // Since `i < maxI` above, the next byte offset `maxI * 64`
            if (balances.length % 2 == 1) {
                require(balances[balances.length-1] <= type(uint128).max, "ByteStorage: too large");
                iByte = maxI * 64;
                assembly {
                    sstore(
                        add(slot, mul(maxI, 32)),
                        add(
                            shl(128, mload(add(balances, add(iByte, 32)))),
                            shr(128, shl(128, sload(add(slot, maxI))))
                        )
                    )
                }
            }
        }
    }

    /**
     * @dev Read `n` balances from storage at position `slot`.
     */
    function readUint128(bytes32 slot, uint256 n) internal view returns (uint256[] memory balances) {
        // Initialize array with length `n`, fill it in via assembly
        balances = new uint256[](n);

        // Shortcut: two balances can be quickly unpacked from one slot
        if (n == 2) {
            assembly {
                mstore(add(balances, 32), shr(128, sload(slot)))
                mstore(add(balances, 64), shr(128, shl(128, sload(slot))))
            }
            return balances;
        }

        /*
        i=1 iByte=0 i%2==1 = false
        2
        3
        4
        */

        uint256 iByte;
        for (uint256 i = 1; i <= n; ++i) {
            iByte = (i-1)/2 * 32; // 0 0 1 1 2 2
            console.log("loop", i, iByte);
            if (i % 2 == 1) {
                assembly { 
                    mstore(
                        // store at index i * 32; i = 0 is skipped by loop
                        add(balances, mul(i, 32)),
                        shr(128, sload(add(slot, iByte)))
                    )
                }
            } else {
                assembly {
                    mstore(
                        add(balances, mul(i, 32)),
                        shr(128, shl(128, sload(add(slot, iByte))))
                    )
                }
            }
        }
    }
}