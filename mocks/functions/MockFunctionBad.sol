/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.20;

import {IWellFunction} from "src/interfaces/IWellFunction.sol";

/**
 * @dev Implements a mock broken WellFunction implementation.
 *
 * Used to verify that {Well.getSwap} throws an error when a Well function
 * returns a reserve that is higher than Well reserves.
 *
 * DO NOT COPY IN PRODUCTION.
 */
contract MockFunctionBad is IWellFunction {
    function calcLpTokenSupply(
        uint256[] memory reserves,
        bytes calldata
    ) external pure returns (uint256 lpTokenSupply) {
        return reserves[0] + reserves[1];
    }

    /// @dev returns non-zero regardless of reserves & lp token supply. WRONG!
    function calcReserve(uint256[] memory, uint256, uint256, bytes calldata) external pure returns (uint256 reserve) {
        return 1000;
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
