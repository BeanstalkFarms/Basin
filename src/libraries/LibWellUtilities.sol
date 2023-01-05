/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "src/interfaces/IWell.sol";

/**
 * @author Publius
 * @title Lib Well Hash contains a function to hash Well info
 **/
library LibWellUtilities {
    /**
     * @dev computes the hash of Well Info
     **/
    function computeWellHash(WellInfo calldata w)
        internal
        pure
        returns (bytes32 wellHash)
    {
        wellHash = keccak256(
            abi.encodePacked(
                abi.encodePacked(w.wellFunction.target, w.wellFunction.data),
                w.tokens,
                abi.encode(w.pumps)
            )
        );
    }
}
