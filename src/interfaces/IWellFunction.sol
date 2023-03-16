// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title IWellFunction
 * @notice Defines a relationship between token reserves and LP token supply.
 * @dev Well Functions can contain arbitrary logic, but should be deterministic
 * if expected to be used alongside a Pump. When interacing with a Well or
 * Well Function, always verify that the Well Function is valid.
 */
interface IWellFunction {
    /**
     * @notice Calculates the `j`th reserve given a list of `reserves` and `lpTokenSupply`.
     * @param reserves A list of token reserves. The jth reserve will be ignored, but a placeholder must be provided.
     * @param j The index of the reserve to solve for
     * @param lpTokenSupply The supply of LP tokens
     * @param data Well function data provided on every call
     * @return reserve The resulting reserve at the jth index
     */
    function calcReserve(
        uint[] memory reserves,
        uint j,
        uint lpTokenSupply,
        bytes calldata data
    ) external view returns (uint reserve);

    /**
     * @notice Gets the LP token supply given a list of reserves.
     * @param reserves A list of token reserves
     * @param data Well function data provided on every call
     * @return lpTokenSupply The resulting supply of LP tokens
     */
    function calcLpTokenSupply(
        uint[] memory reserves,
        bytes calldata data
    ) external view returns (uint lpTokenSupply);

    /**
     * @notice Returns the name of the Well function.
     * @dev Used in Well building.
     */
    function name() external view returns (string memory);

    /**
     * @notice Returns the symbol of the Well function.
     * @dev Used in Well building.
     */
    function symbol() external view returns (string memory);
}
