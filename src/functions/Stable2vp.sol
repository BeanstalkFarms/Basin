// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Stable2, ILookupTable} from "./Stable2.sol";
/**
 * @author Brean, DeadmanWalking
 * @title Gas efficient StableSwap pricing function for Wells with 2 tokens and a virtual price.
 * See {Stable2} for more info.
 *
 * a `virtualPrice` parameter is used to allow for the pairing of like-valued tokens.
 * Future development can be done to implement a virtual price that changes over time
 * (For example, to support a token that accures fees).
 *
 * @dev Limited to tokens with a maximum of 18 decimals.
 * The Stable2 Well Function takes in the following data from the well:
 * - Token[0,1] decimals
 * - VirtualPrice
 * - VirtualPriceIndex
 * if `virtualPrice` is 0, it is assumed to be 1e6.
 * Data is encoded as `abi.encode(uint256[], uint256, uint256)`.
 */

contract Stable2vp is Stable2 {
    constructor(address lut) Stable2(lut) {}

    /**
     * @notice scale `reserves` by decimals encoded in `data`,
     * and scale `tokenIndex` reserve by `virtualPrice`.
     */
    function getScaledReservesAndDecimals(
        uint256[] memory reserves,
        bytes memory data
    ) internal pure virtual override returns (uint256[] memory scaledReserves, uint256[] memory decimals) {
        uint256 virtualPrice;
        uint256 virtualPriceIndex;
        (decimals, virtualPrice, virtualPriceIndex) = getDecimalsAndVirtualPriceFromData(data);
        if (virtualPrice == 0) virtualPrice = PRICE_PRECISION;
        scaledReserves = new uint256[](2);
        for (uint256 i; i < 2; i++) {
            if (i == virtualPriceIndex) {
                scaledReserves[i] = reserves[i] * virtualPrice / PRICE_PRECISION * 10 ** (18 - decimals[i]);
            } else {
                scaledReserves[i] = reserves[i] * 10 ** (18 - decimals[i]);
            }
        }
    }

    /**
     * @notice decodes the data encoded in the well.
     * @return decimals an array of the decimals of the tokens in the well.
     */
    function getDecimalsFromData(bytes memory data) public pure virtual override returns (uint256[] memory decimals) {
        if (data.length == 0) {
            decimals = new uint256[](2);
            decimals[0] = 18;
            decimals[1] = 18;
        }

        (decimals,,) = abi.decode(data, (uint256[], uint256, uint256));

        // if decimals returns 0, assume 18 decimals.
        for (uint256 i; i < 2; i++) {
            if (decimals[i] == 0) decimals[i] = 18;
            if (decimals[i] > 18) revert InvalidTokenDecimals();
        }
    }

    /**
     * @notice returns the decimals, virtualPrice, and virtualPriceIndex from the well data.
     * @dev `virtualPrice` must have 6 decimal precision.
     * if `virtualPrice` is 0, assumes a price of PRICE_PRECISION (1:1).
     */
    function getDecimalsAndVirtualPriceFromData(bytes memory data)
        public
        pure
        returns (uint256[] memory decimals, uint256 virtualPrice, uint256 virtualPriceIndex)
    {
        (decimals, virtualPrice, virtualPriceIndex) = abi.decode(data, (uint256[], uint256, uint256));
        if (virtualPrice == 0) virtualPrice = PRICE_PRECISION;
        // if decimals returns 0, assume 18 decimals.
        for (uint256 i; i < 2; i++) {
            if (decimals[i] == 0) decimals[i] = 18;
            if (decimals[i] > 18) revert InvalidTokenDecimals();
        }
    }

    function name() external pure virtual override returns (string memory) {
        return "Stable2VP";
    }

    function symbol() external pure virtual override returns (string memory) {
        return "S2VP";
    }
}
