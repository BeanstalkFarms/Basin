// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ABDKMathQuad} from "src/libraries/ABDKMathQuad.sol";
import {console} from "forge-std/Test.sol";
import {MultiFlowPump} from "src/pumps/MultiFlowPump.sol";

uint256 constant MAX_128 = 2 ** 128;
uint256 constant MAX_E18 = 1e18;

function from18(uint256 a) pure returns (bytes16 result) {
    return ABDKMathQuad.from128x128(int256((a * MAX_128) / MAX_E18));
}

function to18(bytes16 a) pure returns (uint256 result) {
    return (uint256(ABDKMathQuad.to128x128(a)) * MAX_E18) / MAX_128;
}

function simCapReserve50Percent(
    uint256 lastReserve,
    uint256 reserve,
    uint256 blocks
) view returns (uint256 cappedReserve) {
    uint256 limitReserve = lastReserve * 1e18;

    uint256 multiplier = lastReserve < reserve ? 1.5e6 : 0.5e6;

    uint256 tempReserve;
    for (uint256 i; i < blocks; ++i) {
        unchecked {
            tempReserve = (limitReserve * multiplier) / 1e6;
        }
        if (lastReserve < reserve && tempReserve < limitReserve) {
            limitReserve = type(uint256).max;
            break;
        }
        limitReserve = tempReserve;
    }
    limitReserve = limitReserve / 1e18;

    console.log("limitReserve", limitReserve);
    console.log("lastReserve", lastReserve);
    console.log("reserve", reserve);

    cappedReserve = (lastReserve < reserve && limitReserve < reserve)
        || (lastReserve > reserve && limitReserve > reserve) ? limitReserve : reserve;
}

function generateRandomUpdate(
    uint256 n,
    bytes32 seed
) pure returns (uint256[] memory balances, uint40 timeIncrease, bytes32 newSeed) {
    balances = new uint256[](n);
    seed = stepSeed(seed);
    timeIncrease = uint40(uint256(seed)) % 50_000_000;
    for (uint256 i; i < n; ++i) {
        seed = stepSeed(seed);
        balances[i] = uint256(seed) % 1e32; //
    }
    newSeed = seed;
}

function stepSeed(bytes32 seed) pure returns (bytes32 newSeed) {
    newSeed = keccak256(abi.encode(seed));
}

function encodePumpData(
    bytes16 alpha,
    uint256 capInterval,
    MultiFlowPump.CapReservesParameters memory crp
) pure returns (bytes memory data) {
    data = abi.encode(alpha, capInterval, crp);
}

function mockPumpData() pure returns (bytes memory data) {
    bytes16[][] memory maxRateChanges = new bytes16[][](2);
    maxRateChanges[0] = new bytes16[](2);
    maxRateChanges[1] = new bytes16[](2);
    maxRateChanges[0][1] = from18(0.5e18);
    maxRateChanges[1][0] = from18(0.5e18);

    data = encodePumpData(
        from18(0.9e18), 12, MultiFlowPump.CapReservesParameters(maxRateChanges, from18(0.5e18), from18(0.4761904762e18))
    );
}
