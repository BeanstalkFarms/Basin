// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import "src/interfaces/IWellFunction.sol";

/**
 * @title IBeanstalkWellFunction
 * @notice Defines all necessary functions for a Well Function to be supported by Beanstalk.
 */
interface IBeanstalkWellFunction is IWellFunction {

    // TODO: change to pure
    function calcReserveAtRatioSwap(
        uint[] calldata reserves,
        uint i,
        uint[] calldata ratios,
        bytes calldata data
    ) external view returns (uint reserve);

    function calcReserveAtRatioLiquidity(
        uint[] calldata reserves,
        uint j,
        uint[] calldata ratios,
        bytes calldata data
    ) external pure returns (uint reserve);
}