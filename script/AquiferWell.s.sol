// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {SafeERC20, IERC20} from "oz/token/ERC20/utils/SafeERC20.sol";

import {IWell, Call} from "src/interfaces/IWell.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {IPump} from "src/interfaces/IPump.sol";

import {MockToken} from "mocks/tokens/MockToken.sol";
import {MockPump} from "mocks/pumps/MockPump.sol";

import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";
import {Well} from "src/Well.sol";
import {Auger} from "src/Auger.sol";
import {Aquifer} from "src/Aquifer.sol";

/**
 * @dev Script to deploy a BEAN-ETH {Well} with a ConstantProduct2 pricing function
 * and MockPump via an Aquifer.
 */
contract DeployAquiferWell is Script {
    using SafeERC20 for IERC20;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = new MockToken("Token0","TK0",18); 
        tokens[1] = new MockToken("Token1","TK1",18); 
        
        // Deploy Aquifer/Auger 
        Aquifer aquifer = new Aquifer();
        Auger auger = new Auger();

        // Well Function
        IWellFunction cp2 = new ConstantProduct2();
        Call memory wellFunction = Call(address(cp2), new bytes(0));

        // Pump
        IPump mockPump = new MockPump();
        Call[] memory pumps = new Call[](1);
        pumps[0] = Call(address(mockPump), new bytes(0));

        //bore well
        Well well = Well(aquifer.boreWell(
            tokens,
            wellFunction,
            pumps,
            auger
        ));

        console.log("Deployed CP2 at address: ", address(cp2));
        console.log("Deployed Pump at address: ", address(pumps[0].target));
        console.log("Deployed Well at address: ", address(well));

        console.log(well.name());
        console.log(well.symbol());
        console.log(well.auger());
        console.log(address(well.tokens()[0]));
        console.log(address(well.tokens()[1]));
        


        vm.stopBroadcast();
    }
}