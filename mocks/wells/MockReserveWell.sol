/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.20;

import {IPump} from "src/interfaces/pumps/IPump.sol";
import {Call} from "src/interfaces/IWell.sol";

/**
 * @notice Mock Well that allows setting of reserves.
 */
contract MockReserveWell {
    uint256[] reserves;
    Call _wellFunction;


    constructor() {
        reserves = new uint256[](2);
    }

    function setWellFunction(Call calldata __wellFunction) external {
        _wellFunction = __wellFunction;
    }

    function wellFunction() external view returns (Call memory) {
        return _wellFunction;
    }

    function setReserves(uint256[] memory _reserves) public {
        reserves = _reserves;
    }

    function getReserves() external view returns (uint256[] memory _reserves) {
        _reserves = reserves;
    }

    function update(address pump, uint256[] calldata _reserves, bytes calldata data) external {
        IPump(pump).update(reserves, data);
        setReserves(_reserves);
    }
}
