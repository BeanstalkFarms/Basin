// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title PriceReserveMapping
 * @author DeadmanWalking
 * @notice In order to reasonably use `calcReserveAtRatioSwap` and `calcReserveAtRatioLiquidity` on chain,
 * a lookup table contract is used to decrease the amount of iterations needed to converge into an answer.
 */
interface ILookupTable {
    /**
     * @notice the lookup table returns a series of data, given a price point:
     * @param highPrice the closest price to the targetPrice, where targetPrice < highPrice.
     * @param highPriceI reserve i such that `calcRate(reserve, i, j, data)` == highPrice.
     * @param highPriceJ reserve j such that `calcRate(reserve, i, j, data)` == highPrice.
     * @param lowPrice the closest price to the targetPrice, where targetPrice > lowPrice.
     * @param lowPriceI reserve i such that `calcRate(reserve, i, j, data)` == lowPrice.
     * @param lowPriceJ reserve j such that `calcRate(reserve, i, j, data)` == lowPrice.
     * @param precision the initial reserve values. Assumes the inital reserve i == reserve j
     */
    struct PriceData {
        uint256 highPrice;
        uint256 highPriceI;
        uint256 highPriceJ;
        uint256 lowPrice;
        uint256 lowPriceI;
        uint256 lowPriceJ;
        uint256 precision;
    }

    function getRatiosFromPriceLiquidity(uint256) external view returns (PriceData memory);
    function getRatiosFromPriceSwap(uint256) external view returns (PriceData memory);
    function getAParameter() external view returns (uint256);
}
