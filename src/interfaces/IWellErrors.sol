// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title IWellErrors contains all Well errors.
 * @dev The errors are separated into a different interface so that the {IWell} interface compiles in older Solidity versions (<0.8.4).
 */
interface IWellErrors {
    /**
     * @notice Thrown when an operation would deliver fewer tokens than `minAmountOut`.
     */
    error SlippageOut(uint amountOut, uint minAmountOut);

    /**
     * @notice Thrown when an operation would require more tokens than `maxAmountIn`.
     */
    error SlippageIn(uint amountIn, uint maxAmountIn);

    /**
     * @notice Thrown if one or more tokens used in the operation are not supported by the Well.
     */
    error InvalidTokens();

    /**
     * @notice Thrown if this operation would cause an incorrect change in Well reserves.
     */
    error InvalidReserves();

    /**
     * @notice Thrown if an operation is executed after the provided `deadline` has passed.
     */
    error Expired();
}