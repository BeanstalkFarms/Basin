/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.20;

import "mocks/tokens/MockToken.sol";

/**
 * @author Brendan
 * @title Mock Token No Name
 *
 */
contract MockTokenNoName is MockToken {
    constructor(uint8 __decimals) MockToken("", "", __decimals) {}

    function name() public pure override returns (string memory) {
        revert();
    }

    function symbol() public pure override returns (string memory) {
        revert();
    }
}
