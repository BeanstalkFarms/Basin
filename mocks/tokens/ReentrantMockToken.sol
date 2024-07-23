/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.20;

import "mocks/tokens/MockToken.sol";

/**
 * @author Brendan
 * @title Reentrant Mock Token
 */
contract ReentrantMockToken is MockToken {
    address private target;
    bytes private callData;

    constructor(string memory name, string memory symbol, uint8 __decimals) MockToken(name, symbol, __decimals) {}

    function setCall(address _target, bytes calldata _callData) external {
        target = _target;
        callData = _callData;
    }

    function _beforeTokenTransfer(address, address, uint256) internal virtual override {
        if (target != address(0)) {
            (bool success, bytes memory data) = target.call(callData);
            if (!success) {
                if (data.length == 0) revert();
                assembly {
                    revert(add(32, data), mload(data))
                }
            }
        }
    }
}
