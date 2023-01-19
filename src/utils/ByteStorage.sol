/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

/**
 * @author Publius
 * @title ByteStorage provides an interface for storing bytes.
 **/
contract ByteStorage {

    function storeUint128(bytes32 slot, uint256[] memory balances) internal {
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
            uint256 maxI = balances.length / 2;
            uint256 iByte;
            for (uint i; i < maxI; ++i) {
                require(balances[2*i] <= type(uint128).max, "ByteStorage: too large");
                require(balances[2*i+1] <= type(uint128).max, "ByteStorage: too large");
                iByte = i * 64;
                assembly {
                    sstore(
                        add(slot, i),
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
            if (balances.length % 2 == 1) {
                require(balances[balances.length-1] <= type(uint128).max, "ByteStorage: too large");
                iByte = maxI * 64;
                assembly {
                    sstore(
                        add(slot, maxI),
                        add(
                            shl(128, mload(add(balances, add(iByte, 32)))),
                            shr(128, shl(128, sload(add(slot, maxI))))
                        )
                    )
                }
            }
        }
    }

    function readUint128(bytes32 slot, uint256 n) internal view returns (uint256[] memory balances) {
        balances = new uint256[](n);
        if (n == 2) {
            assembly {
                mstore(add(balances, 32), shr(128, sload(slot)))
                mstore(add(balances, 64), shr(128, shl(128, sload(slot))))
            }
            return balances;
        }
        uint256 iByte;
        for (uint256 i = 1; i <= n; ++i) {
            iByte = (i-1)/2;
            if (i % 2 == 1) {
                assembly { mstore(add(balances, mul(i,32)), shr(128, sload(add(slot,iByte)))) }
            } else {
                assembly { mstore(add(balances, mul(i,32)), sload(add(slot,iByte))) }
            }
        }
    }
}