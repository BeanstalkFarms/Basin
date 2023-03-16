/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import {IWellFunction} from "src/interfaces/IWellFunction.sol";

contract MockEmptyFunction is IWellFunction {

    function calcReserve(
        uint256[] memory,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (uint d) {
        return 1;
    }

    function calcLpTokenSupply(
        uint256[] memory,
        bytes calldata
    ) external pure returns (uint xj) {
        return 1;
    }

    function calcLPTokenUnderlying(
        uint256,
        uint256[] memory,
        uint256,
        bytes calldata
    ) external pure returns (uint[] memory underlyingAmounts) {
        return underlyingAmounts;
    }

    function name() external override pure returns (string memory) {}

    function symbol() external override pure returns (string memory) {}
}