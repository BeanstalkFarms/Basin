/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "src/interfaces/IWellFunction.sol";

contract MockFunctionNoName is IWellFunction {

    function getD(
        bytes calldata,
        uint[] calldata xs
    ) external override pure returns (uint d) {}

    function getXj(
        bytes calldata,
        uint[] calldata xs,
        uint j,
        uint d
    ) external override pure returns (uint xj) {}

    function name() external override pure returns (string memory) {
        revert();
    }

    function symbol() external override pure returns (string memory) {
        revert();
    }
}