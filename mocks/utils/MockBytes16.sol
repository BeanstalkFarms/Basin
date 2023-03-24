// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibBytes16} from "src/libraries/LibBytes16.sol";

/**
 * @title MockBytes16
 */
contract MockBytes16 {

    function packBytes16(
        bytes16[] memory byteArray
    ) external pure returns (bytes memory packedBytes) {
        packedBytes = LibBytes16.packBytes16(byteArray);
    }

    function unpackBytes16(
        bytes calldata packedBytes
    ) external pure returns (bytes16[] memory byteArray) {
        byteArray = LibBytes16.unpackBytes16(packedBytes);
    }
}
