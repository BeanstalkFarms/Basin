// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Auger, IAuger} from "src/Auger.sol";

/// @dev Script to deploy an {Auger}. Augers bore Wells.
contract DeployAuger is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Auger auger = new Auger();
        console.log("Deployed Auger at address: ", address(auger));

        vm.stopBroadcast();
    }
}