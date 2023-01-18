/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "src/interfaces/IWellFunction.sol";

contract MockFunctionNoName is IWellFunction {

    function getBalance(
        uint256[] memory balances,
        uint256 j,
        uint256 lpTokenSupply,
        bytes calldata data
    ) external pure returns (uint d) {}

    function getLpTokenSupply(
        uint256[] memory balances,
        bytes calldata data
    ) external pure returns (uint xj) {}

    function name() external override pure returns (string memory) {
        revert();
    }

    function symbol() external override pure returns (string memory) {
        revert();
    }
}