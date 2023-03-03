// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ABDKMathQuad} from "src/libraries/ABDKMathQuad.sol";
import {console} from "forge-std/Test.sol";

uint constant MAX_128 = 2 ** 128;
uint constant MAX_E18 = 1e18;

function from18(uint a) pure returns (bytes16 result) {
    return ABDKMathQuad.from128x128(int(a * MAX_128 / MAX_E18));
}

function to18(bytes16 a) pure returns (uint result) {
    return uint(ABDKMathQuad.to128x128(a)) * MAX_E18 / MAX_128;
}


function simCapReserve50Percent(uint256 lastReserve, uint256 reserve, uint blocks) view returns (uint256 cappedReserve) {
    uint limitReserve = lastReserve * 1e18;

    uint multiplier = lastReserve < reserve ? 1.5e6 : 0.5e6;

    uint tempReserve;
    for (uint i; i < blocks; ++i) {
        unchecked {
            tempReserve = limitReserve * multiplier / 1e6;
        }
        if (lastReserve < reserve && tempReserve < limitReserve) {
            limitReserve = type(uint).max;
            break;
        }
        limitReserve = tempReserve;
    }
    limitReserve = limitReserve / 1e18;

    console.log("limitReserve", limitReserve);
    console.log("lastReserve", lastReserve);
    console.log("reserve", reserve);

    cappedReserve =
        (lastReserve < reserve && limitReserve < reserve) ||
        (lastReserve > reserve && limitReserve > reserve) ?
        limitReserve : reserve;
}

function generateRandomUpdate(uint n, bytes32 seed) pure returns (uint256[] memory balances, uint40 timeIncrease, bytes32 newSeed) {
    balances = new uint[](n);
    seed = stepSeed(seed);
    timeIncrease = uint40(uint256(seed)) % 50_000_000;
    for (uint i; i < n; ++i) {
        seed = stepSeed(seed);
        balances[i] = uint(uint128(uint(seed))); // case to uin128
    }
    newSeed = seed;
}

function stepSeed(bytes32 seed) pure returns (bytes32 newSeed) {
    newSeed = keccak256(abi.encode(seed));
}