// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IPump} from "src/interfaces/pumps/IPump.sol";

/**
 * @notice Mock Well that allows setting of reserves.
 */
contract MockReserveWell {

    uint[] reserves;

    constructor() {
        reserves = new uint[](2);
    }

    function setReserves(uint[] memory _reserves) public {
        reserves = _reserves;
    }

    function getReserves() external view returns (uint[] memory _reserves) {
        _reserves = reserves;
    }

    function update(address pump, uint[] calldata _reserves, bytes calldata data) external {
        IPump(pump).update(reserves, data);
        setReserves(_reserves);
    }
}
