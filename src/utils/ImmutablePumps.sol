/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "src/interfaces/IWell.sol";
import "src/libraries/LibBytes.sol";

contract ImmutablePumps {
    using LibBytes for bytes;

    bytes32 private constant ZERO_BYTES = bytes32(0);
    address private constant ZERO_TARGET = address(0);

    uint private MAX_CALLS = 6;

    uint private constant MAX_SIZE = 8*32;

    uint private immutable numberOfCalls;
    address private immutable _target0;
    address private immutable _target1;
    address private immutable _target2;
    address private immutable _target3;
    // address private immutable _target4;
    // address private immutable _target5;

    uint private immutable numberOfBytes0;
    bytes32 private immutable _bytes0_0;
    bytes32 private immutable _bytes0_1;
    bytes32 private immutable _bytes0_2;
    bytes32 private immutable _bytes0_3;
    // bytes32 private immutable _bytes0_4;
    // bytes32 private immutable _bytes0_5;
    // bytes32 private immutable _bytes0_6;
    // bytes32 private immutable _bytes0_7;
    
    uint private immutable numberOfBytes1;
    bytes32 private immutable _bytes1_0;
    bytes32 private immutable _bytes1_1;
    bytes32 private immutable _bytes1_2;
    bytes32 private immutable _bytes1_3;
    // bytes32 private immutable _bytes1_4;
    // bytes32 private immutable _bytes1_5;
    // bytes32 private immutable _bytes1_6;
    // bytes32 private immutable _bytes1_7;

    uint private immutable numberOfBytes2;
    bytes32 private immutable _bytes2_0;
    bytes32 private immutable _bytes2_1;
    bytes32 private immutable _bytes2_2;
    bytes32 private immutable _bytes2_3;
    // bytes32 private immutable _bytes2_4;
    // bytes32 private immutable _bytes2_5;
    // bytes32 private immutable _bytes2_6;
    // bytes32 private immutable _bytes2_7;

    uint private immutable numberOfBytes3;
    bytes32 private immutable _bytes3_0;
    bytes32 private immutable _bytes3_1;
    bytes32 private immutable _bytes3_2;
    bytes32 private immutable _bytes3_3;
    // bytes32 private immutable _bytes3_4;
    // bytes32 private immutable _bytes3_5;
    // bytes32 private immutable _bytes3_6;
    // bytes32 private immutable _bytes3_7;

    // uint private immutable numberOfBytes4;
    // bytes32 private immutable _bytes4_0;
    // bytes32 private immutable _bytes4_1;
    // bytes32 private immutable _bytes4_2;
    // bytes32 private immutable _bytes4_3;
    // bytes32 private immutable _bytes4_4;
    // bytes32 private immutable _bytes4_5;
    // bytes32 private immutable _bytes4_6;
    // bytes32 private immutable _bytes4_7;

    // uint private immutable numberOfBytes5;
    // bytes32 private immutable _bytes5_0;
    // bytes32 private immutable _bytes5_1;
    // bytes32 private immutable _bytes5_2;
    // bytes32 private immutable _bytes5_3;
    // bytes32 private immutable _bytes5_4;
    // bytes32 private immutable _bytes5_5;
    // bytes32 private immutable _bytes5_6;
    // bytes32 private immutable _bytes5_7;

    constructor(Call[] memory calls) {

        require(calls.length <= MAX_CALLS, "Too many calls");

        numberOfCalls = calls.length;

        _target0 = getCallTargetFromList(calls, 0);
        _target1 = getCallTargetFromList(calls, 1);
        _target2 = getCallTargetFromList(calls, 2);
        _target3 = getCallTargetFromList(calls, 3);
        // _target4 = getCallTargetFromList(calls, 4);
        // _target5 = getCallTargetFromList(calls, 5);

        uint bytesLegnth = getCallNumberOfBytesFromList(calls, 0);
        require(bytesLegnth <= MAX_SIZE, "Too many bytes");
        numberOfBytes0 = bytesLegnth;
        _bytes0_0 = getCallBytesFromList(calls, 0, 0);
        _bytes0_1 = getCallBytesFromList(calls, 0, 1);
        _bytes0_2 = getCallBytesFromList(calls, 0, 2);
        _bytes0_3 = getCallBytesFromList(calls, 0, 3);
        // _bytes0_4 = getCallBytesFromList(calls, 0, 4);
        // _bytes0_5 = getCallBytesFromList(calls, 0, 5);
        // _bytes0_6 = getCallBytesFromList(calls, 0, 6);
        // _bytes0_7 = getCallBytesFromList(calls, 0, 7);

        bytesLegnth = getCallNumberOfBytesFromList(calls, 1);
        require(bytesLegnth <= MAX_SIZE, "Too many bytes");
        numberOfBytes1 = bytesLegnth;
        _bytes1_0 = getCallBytesFromList(calls, 1, 0);
        _bytes1_1 = getCallBytesFromList(calls, 1, 1);
        _bytes1_2 = getCallBytesFromList(calls, 1, 2);
        _bytes1_3 = getCallBytesFromList(calls, 1, 3);
        // _bytes1_4 = getCallBytesFromList(calls, 1, 4);
        // _bytes1_5 = getCallBytesFromList(calls, 1, 5);
        // _bytes1_6 = getCallBytesFromList(calls, 1, 6);
        // _bytes1_7 = getCallBytesFromList(calls, 1, 7);

        bytesLegnth = getCallNumberOfBytesFromList(calls, 2);
        require(bytesLegnth <= MAX_SIZE, "Too many bytes");
        numberOfBytes2 = bytesLegnth;
        _bytes2_0 = getCallBytesFromList(calls, 2, 0);
        _bytes2_1 = getCallBytesFromList(calls, 2, 1);
        _bytes2_2 = getCallBytesFromList(calls, 2, 2);
        _bytes2_3 = getCallBytesFromList(calls, 2, 3);
        // _bytes2_4 = getCallBytesFromList(calls, 2, 4);
        // _bytes2_5 = getCallBytesFromList(calls, 2, 5);
        // _bytes2_6 = getCallBytesFromList(calls, 2, 6);
        // _bytes2_7 = getCallBytesFromList(calls, 2, 7);

        bytesLegnth = getCallNumberOfBytesFromList(calls, 3);
        require(bytesLegnth <= MAX_SIZE, "Too many bytes");
        numberOfBytes3 = bytesLegnth;
        _bytes3_0 = getCallBytesFromList(calls, 3, 0);
        _bytes3_1 = getCallBytesFromList(calls, 3, 1);
        _bytes3_2 = getCallBytesFromList(calls, 3, 2);
        _bytes3_3 = getCallBytesFromList(calls, 3, 3);
        // _bytes3_4 = getCallBytesFromList(calls, 3, 4);
        // _bytes3_5 = getCallBytesFromList(calls, 3, 5);
        // _bytes3_6 = getCallBytesFromList(calls, 3, 6);
        // _bytes3_7 = getCallBytesFromList(calls, 3, 7);

        // bytesLegnth = getCallNumberOfBytesFromList(calls, 4);
        // require(bytesLegnth <= MAX_SIZE, "Too many bytes");
        // numberOfBytes4 = bytesLegnth;
        // _bytes4_0 = getCallBytesFromList(calls, 4, 0);
        // _bytes4_1 = getCallBytesFromList(calls, 4, 1);
        // _bytes4_2 = getCallBytesFromList(calls, 4, 2);
        // _bytes4_3 = getCallBytesFromList(calls, 4, 3);
        // _bytes4_4 = getCallBytesFromList(calls, 4, 4);
        // _bytes4_5 = getCallBytesFromList(calls, 4, 5);
        // _bytes4_6 = getCallBytesFromList(calls, 4, 6);
        // _bytes4_7 = getCallBytesFromList(calls, 4, 7);

        // bytesLegnth = getCallNumberOfBytesFromList(calls, 5);
        // require(bytesLegnth <= MAX_SIZE, "Too many bytes");
        // numberOfBytes5 = bytesLegnth;
        // _bytes5_0 = getCallBytesFromList(calls, 5, 0);
        // _bytes5_1 = getCallBytesFromList(calls, 5, 1);
        // _bytes5_2 = getCallBytesFromList(calls, 5, 2);
        // _bytes5_3 = getCallBytesFromList(calls, 5, 3);
        // _bytes5_4 = getCallBytesFromList(calls, 5, 4);
        // _bytes5_5 = getCallBytesFromList(calls, 5, 5);
        // _bytes5_6 = getCallBytesFromList(calls, 5, 6);
        // _bytes5_7 = getCallBytesFromList(calls, 5, 7);
    }

    function getCallTargetFromList(Call[] memory calls, uint i) private pure returns (address _target) {
        if (i >= calls.length) _target = ZERO_TARGET;
        else _target = calls[i].target;
    }

    function getCallBytesFromList(Call[] memory calls, uint i, uint j) private pure returns (bytes32 _bytes) {
        if (i >= calls.length) _bytes = ZERO_BYTES;
        else _bytes = calls[i].data.getBytes32FromBytes(j);
    }

    function getCallNumberOfBytesFromList(Call[] memory calls, uint i) private pure returns (uint numberOfBytes) {
        if (i >= calls.length) numberOfBytes = 0;
        else numberOfBytes = calls[i].data.length;
    }

    function firstPumpAddress() public view returns (address _target) {
        _target = _target0;
    }

    function firstPumpBytes() public view returns (bytes memory _bytes) {
        if (numberOfBytes0 > 0) {
            bytes32 temp;
            uint slots = (numberOfBytes0-1) / 32 + 1;
            _bytes = new bytes(numberOfBytes0);
            temp = _bytes0_0;
            assembly { mstore(add(_bytes, 0x20), temp)}
            if (slots > 1) {
                temp = _bytes0_1;
                assembly { mstore(add(_bytes, 0x40), temp)}
                if (slots > 2) {
                    temp = _bytes0_2;
                    assembly { mstore(add(_bytes, 0x60), temp)}
                    if (slots > 3) {
                        temp = _bytes0_3;
                        assembly { mstore(add(_bytes, 0x80), temp)}
                        // if (slots > 4) {
                        //     temp = _bytes0_4;
                        //     assembly { mstore(add(_bytes, 0xa0), temp)}
                        //     if (slots > 5) {
                        //         temp = _bytes0_5;
                        //         assembly { mstore(add(_bytes, 0xc0), temp)}
                        //         if (slots > 6) {
                        //             temp = _bytes0_6;
                        //             assembly { mstore(add(_bytes, 0xe0), temp)}
                        //             if (slots > 7) {
                        //                 temp = _bytes0_7;
                        //                 assembly { mstore(add(_bytes, 0x100), temp)}
                        //             }
                        //         }
                        //     }
                        // }
                    }
                }
            }
        }
    }

    function numberOfPumps() public view returns (uint _numberOfPumps) {
        _numberOfPumps = numberOfCalls;
    }

    function pumps() public virtual view returns (Call[] memory _calls) {
        _calls = new Call[](numberOfCalls);

        if (numberOfCalls == 0) return _calls;

        _calls[0].target = _target0;
        bytes32 temp;
        bytes memory tempBytes;
        uint slots;

        if (numberOfBytes0 > 0) {
            slots = (numberOfBytes0-1) / 32 + 1;
            tempBytes = new bytes(numberOfBytes0);
            temp = _bytes0_0;
            assembly { mstore(add(tempBytes, 0x20), temp)}
            if (slots > 1) {
                temp = _bytes0_1;
                assembly { mstore(add(tempBytes, 0x40), temp)}
                if (slots > 2) {
                    temp = _bytes0_2;
                    assembly { mstore(add(tempBytes, 0x60), temp)}
                    if (slots > 3) {
                        temp = _bytes0_3;
                        assembly { mstore(add(tempBytes, 0x80), temp)}
                        // if (slots > 4) {
                        //     temp = _bytes0_4;
                        //     assembly { mstore(add(tempBytes, 0xa0), temp)}
                        //     if (slots > 5) {
                        //         temp = _bytes0_5;
                        //         assembly { mstore(add(tempBytes, 0xc0), temp)}
                        //         if (slots > 6) {
                        //             temp = _bytes0_6;
                        //             assembly { mstore(add(tempBytes, 0xe0), temp)}
                        //             if (slots > 7) {
                        //                 temp = _bytes0_7;
                        //                 assembly { mstore(add(tempBytes, 0x100), temp)}
                        //             }
                        //         }
                        //     }
                        // }
                    }
                }
            }
            _calls[0].data = tempBytes;
        }

        if (numberOfCalls == 1) return _calls;

        _calls[1].target = _target1;

        if (numberOfBytes1 > 0) {
            slots = (numberOfBytes1-1) / 32 + 1;
            tempBytes = new bytes(numberOfBytes1);
            temp = _bytes1_0;
            assembly { mstore(add(tempBytes, 0x20), temp)}
            if (slots > 1) {
                temp = _bytes1_1;
                assembly { mstore(add(tempBytes, 0x40), temp)}
                if (slots > 2) {
                    temp = _bytes1_2;
                    assembly { mstore(add(tempBytes, 0x60), temp)}
                    if (slots > 3) {
                        temp = _bytes1_3;
                        assembly { mstore(add(tempBytes, 0x80), temp)}
                        // if (slots > 4) {
                        //     temp = _bytes1_4;
                        //     assembly { mstore(add(tempBytes, 0xa0), temp)}
                        //     if (slots > 5) {
                        //         temp = _bytes1_5;
                        //         assembly { mstore(add(tempBytes, 0xc0), temp)}
                        //         if (slots > 6) {
                        //             temp = _bytes1_6;
                        //             assembly { mstore(add(tempBytes, 0xe0), temp)}
                        //             if (slots > 7) {
                        //                 temp = _bytes1_7;
                        //                 assembly { mstore(add(tempBytes, 0x100), temp)}
                        //             }
                        //         }
                        //     }
                        // }
                    }
                }
            }
            _calls[1].data = tempBytes;
        }

        if (numberOfCalls == 2) return _calls;

        _calls[2].target = _target2;

        if (numberOfBytes2 > 0) {
            slots = (numberOfBytes2-1) / 32 + 1;
            tempBytes = new bytes(numberOfBytes2);
            temp = _bytes2_0;
            assembly { mstore(add(tempBytes, 0x20), temp)}
            if (slots > 1) {
                temp = _bytes2_1;
                assembly { mstore(add(tempBytes, 0x40), temp)}
                if (slots > 2) {
                    temp = _bytes2_2;
                    assembly { mstore(add(tempBytes, 0x60), temp)}
                    if (slots > 3) {
                        temp = _bytes2_3;
                        assembly { mstore(add(tempBytes, 0x80), temp)}
                        // if (slots > 4) {
                        //     temp = _bytes2_4;
                        //     assembly { mstore(add(tempBytes, 0xa0), temp)}
                        //     if (slots > 5) {
                        //         temp = _bytes2_5;
                        //         assembly { mstore(add(tempBytes, 0xc0), temp)}
                        //         if (slots > 6) {
                        //             temp = _bytes2_6;
                        //             assembly { mstore(add(tempBytes, 0xe0), temp)}
                        //             if (slots > 7) {
                        //                 temp = _bytes2_7;
                        //                 assembly { mstore(add(tempBytes, 0x100), temp)}
                        //             }
                        //         }
                        //     }
                        // }
                    }
                }
            }
            _calls[2].data = tempBytes;
        }

        if (numberOfCalls == 3) return _calls;

        _calls[3].target = _target3;

        if (numberOfBytes3 > 0) {
            slots = (numberOfBytes3-1) / 32 + 1;
            tempBytes = new bytes(numberOfBytes3);
            temp = _bytes3_0;
            assembly { mstore(add(tempBytes, 0x20), temp)}
            if (slots > 1) {
                temp = _bytes3_1;
                assembly { mstore(add(tempBytes, 0x40), temp)}
                if (slots > 2) {
                    temp = _bytes3_2;
                    assembly { mstore(add(tempBytes, 0x60), temp)}
                    if (slots > 3) {
                        temp = _bytes3_3;
                        assembly { mstore(add(tempBytes, 0x80), temp)}
                        // if (slots > 4) {
                        //     temp = _bytes3_4;
                        //     assembly { mstore(add(tempBytes, 0xa0), temp)}
                        //     if (slots > 5) {
                        //         temp = _bytes3_5;
                        //         assembly { mstore(add(tempBytes, 0xc0), temp)}
                        //         if (slots > 6) {
                        //             temp = _bytes3_6;
                        //             assembly { mstore(add(tempBytes, 0xe0), temp)}
                        //             if (slots > 7) {
                        //                 temp = _bytes3_7;
                        //                 assembly { mstore(add(tempBytes, 0x100), temp)}
                        //             }
                        //         }
                        //     }
                        // }
                    }
                }
            }
            _calls[3].data = tempBytes;
        }

        // if (numberOfCalls == 4) return _calls;

        // _calls[4].target = _target4;

        // if (numberOfBytes4 > 0) {
        //     slots = (numberOfBytes4-1) / 32 + 1;
        //     tempBytes = new bytes(numberOfBytes4);
        //     temp = _bytes4_0;
        //     assembly { mstore(add(tempBytes, 0x20), temp)}
        //     if (slots > 1) {
        //         temp = _bytes4_1;
        //         assembly { mstore(add(tempBytes, 0x40), temp)}
        //         if (slots > 2) {
        //             temp = _bytes4_2;
        //             assembly { mstore(add(tempBytes, 0x60), temp)}
        //             if (slots > 3) {
        //                 temp = _bytes4_3;
        //                 assembly { mstore(add(tempBytes, 0x80), temp)}
        //                 if (slots > 4) {
        //                     temp = _bytes4_4;
        //                     assembly { mstore(add(tempBytes, 0xa0), temp)}
        //                     if (slots > 5) {
        //                         temp = _bytes4_5;
        //                         assembly { mstore(add(tempBytes, 0xc0), temp)}
        //                         if (slots > 6) {
        //                             temp = _bytes4_6;
        //                             assembly { mstore(add(tempBytes, 0xe0), temp)}
        //                             if (slots > 7) {
        //                                 temp = _bytes4_7;
        //                                 assembly { mstore(add(tempBytes, 0x100), temp)}
        //                             }
        //                         }
        //                     }
        //                 }
        //             }
        //         }
        //     }
        //     _calls[4].data = tempBytes;
        // }

        // if (numberOfCalls == 5) return _calls;

        // _calls[5].target = _target5;

        // if (slots > numberOfBytes5) {
        //     slots = (numberOfBytes5-1) / 32 + 1;
        //     tempBytes = new bytes(numberOfBytes5);
        //     temp = _bytes5_0;
        //     assembly { mstore(add(tempBytes, 0x20), temp)}
        //     if (slots > 1) {
        //         temp = _bytes5_1;
        //         assembly { mstore(add(tempBytes, 0x40), temp)}
        //         if (slots > 2) {
        //             temp = _bytes5_2;
        //             assembly { mstore(add(tempBytes, 0x60), temp)}
        //             if (slots > 3) {
        //                 temp = _bytes5_3;
        //                 assembly { mstore(add(tempBytes, 0x80), temp)}
        //                 if (slots > 4) {
        //                     temp = _bytes5_4;
        //                     assembly { mstore(add(tempBytes, 0xa0), temp)}
        //                     if (slots > 5) {
        //                         temp = _bytes5_5;
        //                         assembly { mstore(add(tempBytes, 0xc0), temp)}
        //                         if (slots > 6) {
        //                             temp = _bytes5_6;
        //                             assembly { mstore(add(tempBytes, 0xe0), temp)}
        //                             if (slots > 7) {
        //                                 temp = _bytes5_7;
        //                                 assembly { mstore(add(tempBytes, 0x100), temp)}
        //                             }
        //                         }
        //                     }
        //                 }
        //             }
        //         }
        //     }
        //     _calls[5].data = tempBytes;
        // }

        return _calls;
    }
}
