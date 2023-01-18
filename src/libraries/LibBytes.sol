/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

/**
 * @author Publius
 * @title Lib Bytes contains bytes operations
 **/

library LibBytes {

    bytes32 private constant ZERO_BYTES = bytes32(0);

    function getBytes32FromBytes(bytes memory data, uint i) internal pure returns (bytes32 _bytes) {
        uint index = i * 32;
        if (index > data.length) {
            _bytes = ZERO_BYTES;
        } else {
            assembly {
                _bytes := mload(add(add(data, index), 32))
            }
        }
    }
}
