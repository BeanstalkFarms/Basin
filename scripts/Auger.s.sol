// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Auger} from "../src/Augers/Auger.sol";

// Script to deploy an {Auger}.
// Augers bore wells.
contract AugerScript is Script {
    function run() external {
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // private key for forge testing: 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
        uint256 deployerPrivateKey = 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266;
        vm.startBroadcast(deployerPrivateKey);
        Auger auger = new Auger();
        vm.stopBroadcast();
    }
}