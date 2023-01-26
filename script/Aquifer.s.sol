// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Aquifer} from "src/Aquifer.sol";

// Script to deploy an {Aquifer}.
// see {Aquifer}.
contract DeployAquifer is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        Aquifer aquifer = new Aquifer();
        vm.stopBroadcast();
    }
}