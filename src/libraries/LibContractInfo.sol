// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title LibContractInfo
 * @notice Contains logic to call functions that return information about a given contract.
 */
library LibContractInfo {
    /**
     * @notice gets the symbol of a given contract
     * @param _contract The contract to get the symbol of
     * @return symbol The symbol of the contract
     * @dev if the contract does not have a symbol function, the first 4 bytes of the address are returned
     */
    function getSymbol(address _contract) internal view returns (string memory symbol) {
        (bool success, bytes memory data) = _contract.staticcall(abi.encodeWithSignature("symbol()"));
        symbol = new string(4);
        if (success) {
            symbol = abi.decode(data, (string));
        } else {
            assembly {
                mstore(add(symbol, 0x20), shl(224, shr(128, _contract)))
            }
        }
    }

    /**
     * @notice gets the name of a given contract
     * @param _contract The contract to get the name of
     * @return name The name of the contract
     * @dev if the contract does not have a name function, the first 8 bytes of the address are returned
     */
    function getName(address _contract) internal view returns (string memory name) {
        (bool success, bytes memory data) = _contract.staticcall(abi.encodeWithSignature("name()"));
        name = new string(8);
        if (success) {
            name = abi.decode(data, (string));
        } else {
            assembly {
                mstore(add(name, 0x20), shl(224, shr(128, _contract)))
            }
        }
    }

    /**
     * @notice gets the decimals of a given contract
     * @param _contract The contract to get the decimals of
     * @return decimals The decimals of the contract
     * @dev if the contract does not have a decimals function, 18 is returned
     */
    function getDecimals(address _contract) internal view returns (uint8 decimals) {
        (bool success, bytes memory data) = _contract.staticcall(abi.encodeWithSignature("decimals()"));
        decimals = success ? abi.decode(data, (uint8)) : 18; // default to 18 decimals
    }
}
