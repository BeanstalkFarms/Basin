// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {MockPump} from "../mocks/pumps/MockPump.sol";

// Script to deploy a {MockPump}.
// Mockpump does not provide utility and is solely used for example.
contract DeployMockPump is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        MockPump mockPump = new MockPump();
        console.log("Deployed MockPump at address: ", address(mockPump));

        vm.stopBroadcast();
    }
}