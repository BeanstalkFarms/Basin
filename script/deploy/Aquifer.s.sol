// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Aquifer} from "src/Aquifer.sol";

// Script to deploy an {Aquifer}.
// see {Aquifer}.
contract DeployAquifer is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // Aquifer aquifer = new Aquifer();
        vm.stopBroadcast();
    }
}
