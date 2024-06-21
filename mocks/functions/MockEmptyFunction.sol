/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.20;

import {IWellFunction} from "src/interfaces/IWellFunction.sol";

contract MockEmptyFunction is IWellFunction {
    function calcReserve(uint256[] memory, uint256, uint256, bytes calldata) external pure returns (uint256 d) {
        return 1;
    }

    function calcLpTokenSupply(uint256[] memory, bytes calldata) external pure returns (uint256 xj) {
        return 1;
    }

    function calcLPTokenUnderlying(
        uint256,
        uint256[] memory,
        uint256,
        bytes calldata
    ) external pure returns (uint256[] memory underlyingAmounts) {
        return underlyingAmounts;
    }

    function name() external pure override returns (string memory) {}

    function symbol() external pure override returns (string memory) {}
}
