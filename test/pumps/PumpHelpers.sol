// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "src/libraries/ABDKMathQuad.sol";

uint constant MAX_128 = 2 ** 128;
uint constant MAX_E18 = 1e18;

function from18(uint a) pure returns (bytes16 result) {
    return ABDKMathQuad.from128x128(int(a * MAX_128 / MAX_E18));
}

function to18(bytes16 a) pure returns (uint result) {
    return uint(ABDKMathQuad.to128x128(a)) * MAX_E18 / MAX_128;
}
