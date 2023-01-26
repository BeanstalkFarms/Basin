// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/console2.sol";
import "forge-std/console.sol";
import "forge-std/Test.sol";
import "forge-std/Script.sol";
import {Well, Call, IWellFunction, IPump, IERC20} from '../src/Well.sol';
import {ConstantProduct2} from '../src/functions/ConstantProduct2.sol';
import {MockPump} from '../mocks/pumps/MockPump.sol';

/**
 * @dev Deploys a BEAN:WETH ConstantProduct2 Well.
 * 
 * Intended for testing.
 */
contract DeployWell is Script {

    IERC20 constant BEAN = IERC20(0xBEA0000029AD1c77D3d5D23Ba2D8893dB9d1Efab);
    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH9

    function run() external {
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // private key for: 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
        vm.startBroadcast(uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = BEAN;
        tokens[1] = WETH;

        IWellFunction cp2 = new ConstantProduct2();
        Call memory wellFunction = Call(address(cp2), new bytes(0));

        IPump mockPump = new MockPump();
        Call[] memory pumps = new Call[](1);
        pumps[0] = Call(address(mockPump), new bytes(0));

        Well well = new Well(
            "BEAN:WETH Constant Product Well",
            "BEAN:WETH",
            tokens,
            wellFunction,
            pumps
        );

        console.log("Deployer", address(this));
        console.log("Balance", address(this).balance);
        console.log("Deployed CP2 at address: ", address(cp2));
        console.log("Deployed Pump at address: ", address(pumps[0].target));
        console.log("Deployed Well at address: ", address(well));
        console.log(address(well.tokens()[0]));
        console.log(address(well.tokens()[1]));

        vm.stopBroadcast();
    }
}