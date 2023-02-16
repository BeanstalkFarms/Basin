/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "oz/token/ERC20/IERC20.sol";

/**
 * @title LibContractInfo contains logic to call functions that return information about a given contract.
 **/
library LibContractInfo {

    /**
     * @notice gets the symbol of a given contract
     * @param _contract The contract to get the symbol of
     * @return symbol The symbol of the contract
     * @dev if the contract does not have a symbol function, the first 4 bytes of the address are returned
     */
    function getSymbol(address _contract) internal view returns (string memory symbol) {
        (bool success, bytes memory data) = _contract.staticcall(abi.encodeWithSignature("symbol()"));
        if (success) {
            symbol = abi.decode(data, (string));
        } else {
            symbol = new string(4);
            assembly {
                symbol := _contract
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
        if (success) {
            name = abi.decode(data, (string));
        } else {
            name = new string(8);
            assembly {
                name := _contract
            }
        }
    }

}