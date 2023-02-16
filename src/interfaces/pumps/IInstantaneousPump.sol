// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;
pragma abicoder v2;

/**
 * @title Instantaneous Pumps provide an Oracle for instantaneous reserves.
 */
interface IInstantaneousPump {
    /**
     * @notice Reads instantaneous reserves from the Pump
     * @param well The address of the Well
     * @return reserves The instantaneous balanecs tracked by the Pump
     */
    function readInstantaneousReserves(address well) external view returns (uint[] memory reserves);
}
