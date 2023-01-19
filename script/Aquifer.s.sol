// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Aquifer} from "../src/aquifers/Aquifer.sol";

// Script to deploy an {Aquifer}.
// see {Aquifer}.
contract AquiferScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("ANVILPK");
        vm.startBroadcast(deployerPrivateKey);
        Aquifer aquifer = new Aquifer();
        vm.stopBroadcast();
    }
}