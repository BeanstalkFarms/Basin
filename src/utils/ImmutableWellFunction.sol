/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "src/interfaces/IWell.sol";
import "src/libraries/LibBytes.sol";

contract ImmutableWellFunction {
    using LibBytes for bytes;

    uint private constant MAX_SIZE = 32*32;
    bytes32 private constant ZERO_BYTES = bytes32(0);

    address private immutable _address;

    uint private immutable numberOfBytes;
    bytes32 private immutable _bytes0;
    bytes32 private immutable _bytes1;
    bytes32 private immutable _bytes2;
    bytes32 private immutable _bytes3;
    bytes32 private immutable _bytes4;
    bytes32 private immutable _bytes5;
    bytes32 private immutable _bytes6;
    bytes32 private immutable _bytes7;
    bytes32 private immutable _bytes8;
    bytes32 private immutable _bytes9;
    bytes32 private immutable _bytes10;
    bytes32 private immutable _bytes11;
    bytes32 private immutable _bytes12;
    bytes32 private immutable _bytes13;
    bytes32 private immutable _bytes14;
    bytes32 private immutable _bytes15;
    bytes32 private immutable _bytes16;
    bytes32 private immutable _bytes17;
    bytes32 private immutable _bytes18;
    bytes32 private immutable _bytes19;
    bytes32 private immutable _bytes20;
    bytes32 private immutable _bytes21;
    bytes32 private immutable _bytes22;
    bytes32 private immutable _bytes23;
    bytes32 private immutable _bytes24;
    bytes32 private immutable _bytes25;
    bytes32 private immutable _bytes26;
    bytes32 private immutable _bytes27;
    bytes32 private immutable _bytes28;
    bytes32 private immutable _bytes29;
    bytes32 private immutable _bytes30;
    bytes32 private immutable _bytes31;

    constructor(Call memory _call) {
        require(_call.target != address(0), "Target address cannot be zero");
        _address = _call.target;

        bytes memory data = _call.data;
        require(data.length <= MAX_SIZE, "Bytes too long");
        numberOfBytes = data.length;
        _bytes0 = data.getBytes32FromBytes(0);
        _bytes1 = data.getBytes32FromBytes(1);
        _bytes2 = data.getBytes32FromBytes(2);
        _bytes3 = data.getBytes32FromBytes(3);
        _bytes4 = data.getBytes32FromBytes(4);
        _bytes5 = data.getBytes32FromBytes(5);
        _bytes6 = data.getBytes32FromBytes(6);
        _bytes7 = data.getBytes32FromBytes(7);
        _bytes8 = data.getBytes32FromBytes(8);
        _bytes9 = data.getBytes32FromBytes(9);
        _bytes10 = data.getBytes32FromBytes(10);
        _bytes11 = data.getBytes32FromBytes(11);
        _bytes12 = data.getBytes32FromBytes(12);
        _bytes13 = data.getBytes32FromBytes(13);
        _bytes14 = data.getBytes32FromBytes(14);
        _bytes15 = data.getBytes32FromBytes(15);
        _bytes16 = data.getBytes32FromBytes(16);
        _bytes17 = data.getBytes32FromBytes(17);
        _bytes18 = data.getBytes32FromBytes(18);
        _bytes19 = data.getBytes32FromBytes(19);
        _bytes20 = data.getBytes32FromBytes(20);
        _bytes21 = data.getBytes32FromBytes(21);
        _bytes22 = data.getBytes32FromBytes(22);
        _bytes23 = data.getBytes32FromBytes(23);
        _bytes24 = data.getBytes32FromBytes(24);
        _bytes25 = data.getBytes32FromBytes(25);
        _bytes26 = data.getBytes32FromBytes(26);
        _bytes27 = data.getBytes32FromBytes(27);
        _bytes28 = data.getBytes32FromBytes(28);
        _bytes29 = data.getBytes32FromBytes(29);
        _bytes30 = data.getBytes32FromBytes(30);
        _bytes31 = data.getBytes32FromBytes(31);
    }

    function wellFunction() public virtual view returns (Call memory _call) {
        _call.data = wellFunctionBytes();
        _call.target = _address;
    }

    function wellFunctionAddress() public view returns (address __address) {
        __address = _address;
    }

    function wellFunctionBytes() public view returns (bytes memory _bytes) {
        if (numberOfBytes == 0) return _bytes;

        _bytes = new bytes(numberOfBytes);
        uint slots = (numberOfBytes-1) / 32 + 1;
        bytes32 temp;

        temp = _bytes0;
        assembly { mstore(add(_bytes, 32), temp) }
        if (slots == 1) return _bytes;

        temp = _bytes1;
        assembly { mstore(add(_bytes, 64), temp) }
        if (slots == 2) return _bytes;

        temp = _bytes2;
        assembly { mstore(add(_bytes, 96), temp) }
        if (slots == 3) return _bytes;

        temp = _bytes3;
        assembly { mstore(add(_bytes, 128), temp) }
        if (slots == 4) return _bytes;

        temp = _bytes4;
        assembly { mstore(add(_bytes, 160), temp) }
        if (slots == 5) return _bytes;

        temp = _bytes5;
        assembly { mstore(add(_bytes, 192), temp) }
        if (slots == 6) return _bytes;

        temp = _bytes6;
        assembly { mstore(add(_bytes, 224), temp) }
        if (slots == 7) return _bytes;

        temp = _bytes7;
        assembly { mstore(add(_bytes, 256), temp) }
        if (slots == 8) return _bytes;

        temp = _bytes8;
        assembly { mstore(add(_bytes, 288), temp) }
        if (slots == 9) return _bytes;

        temp = _bytes9;
        assembly { mstore(add(_bytes, 320), temp) }
        if (slots == 10) return _bytes;

        temp = _bytes10;
        assembly { mstore(add(_bytes, 352), temp) }
        if (slots == 11) return _bytes;

        temp = _bytes11;
        assembly { mstore(add(_bytes, 384), temp) }
        if (slots == 12) return _bytes;

        temp = _bytes12;
        assembly { mstore(add(_bytes, 416), temp) }
        if (slots == 13) return _bytes;

        temp = _bytes13;
        assembly { mstore(add(_bytes, 448), temp) }
        if (slots == 14) return _bytes;

        temp = _bytes14;
        assembly { mstore(add(_bytes, 480), temp) }
        if (slots == 15) return _bytes;

        temp = _bytes15;
        assembly { mstore(add(_bytes, 512), temp) }
        if (slots == 16) return _bytes;

        temp = _bytes16;
        assembly { mstore(add(_bytes, 544), temp) }
        if (slots == 17) return _bytes;

        temp = _bytes17;
        assembly { mstore(add(_bytes, 576), temp) }
        if (slots == 18) return _bytes;

        temp = _bytes18;
        assembly { mstore(add(_bytes, 608), temp) }
        if (slots == 19) return _bytes;

        temp = _bytes19;
        assembly { mstore(add(_bytes, 640), temp) }
        if (slots == 20) return _bytes;

        temp = _bytes20;
        assembly { mstore(add(_bytes, 672), temp) }
        if (slots == 21) return _bytes;

        temp = _bytes21;
        assembly { mstore(add(_bytes, 704), temp) }
        if (slots == 22) return _bytes;

        temp = _bytes22;
        assembly { mstore(add(_bytes, 736), temp) }
        if (slots == 23) return _bytes;

        temp = _bytes23;
        assembly { mstore(add(_bytes, 768), temp) }
        if (slots == 24) return _bytes;

        temp = _bytes24;
        assembly { mstore(add(_bytes, 800), temp) }
        if (slots == 25) return _bytes;

        temp = _bytes25;
        assembly { mstore(add(_bytes, 832), temp) }
        if (slots == 26) return _bytes;

        temp = _bytes26;
        assembly { mstore(add(_bytes, 864), temp) }
        if (slots == 27) return _bytes;

        temp = _bytes27;
        assembly { mstore(add(_bytes, 896), temp) }
        if (slots == 28) return _bytes;

        temp = _bytes28;
        assembly { mstore(add(_bytes, 928), temp) }
        if (slots == 29) return _bytes;

        temp = _bytes29;
        assembly { mstore(add(_bytes, 960), temp) }
        if (slots == 30) return _bytes;

        temp = _bytes30;
        assembly { mstore(add(_bytes, 992), temp) }
        if (slots == 31) return _bytes;

        temp = _bytes31;
        assembly { mstore(add(_bytes, 1024), temp) }
        return _bytes;
    }
}
