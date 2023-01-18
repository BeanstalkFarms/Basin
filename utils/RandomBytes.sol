// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6; // FIXME: changed from 0.8.0

contract RandomBytes {
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    function getRandomBytes(uint n) internal view returns (bytes memory _bytes) {
        _bytes = new bytes(n);
        bytes32 temp;
        for (uint i = 32; i < n+32; i += 32) {
            temp = keccak256(abi.encode(block.timestamp + i));
            assembly { mstore(add(_bytes, i), temp) }
        }
    }

    function getRandomAddress(uint seed) internal view returns (address __address) {
        bytes32 _bytes = keccak256(abi.encodePacked(block.timestamp, seed));
        assembly { __address := mload(add(_bytes, 32)) }
    }
}