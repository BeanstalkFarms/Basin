// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {WellUpgradeable} from "src/WellUpgradeable.sol";

// this needs to be here for upgrade checks
/// @custom:oz-upgrades-from WellUpgradeable
contract MockWellUpgradeable is WellUpgradeable {

    function getVersion(uint256 i) external pure returns (uint256) {
        return i;
    }
}