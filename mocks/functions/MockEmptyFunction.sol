/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import {IWellFunction} from "src/interfaces/IWellFunction.sol";

contract MockEmptyFunction is IWellFunction {

    function calcReserve(
        uint256[] memory reserves,
        uint256 j,
        uint256 lpTokenSupply,
        bytes calldata data
    ) external pure returns (uint d) {
        return 1;
    }

    function calcLpTokenSupply(
        uint256[] memory reserves,
        bytes calldata data
    ) external pure returns (uint xj) {
        return 1;
    }

    function name() external override pure returns (string memory) {}

    function symbol() external override pure returns (string memory) {}
}