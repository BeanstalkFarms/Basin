/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.13;

import "forge-std/console2.sol";
import "forge-std/console.sol";
import "forge-std/Test.sol";
import "forge-std/Script.sol";

import {logger} from "script/helpers/Logger.sol";
import {MockPump} from 'mocks/pumps/MockPump.sol';

import {Well, Call, IWellFunction, IPump, IERC20} from 'src/Well.sol';
import {ConstantProduct2} from 'src/functions/ConstantProduct2.sol';

/**
 * @dev Deploys a BEAN:WETH ConstantProduct2 Well. Intended for testing.
 */
contract DeployWell is Script {

    IERC20 constant BEAN = IERC20(0xBEA0000029AD1c77D3d5D23Ba2D8893dB9d1Efab);
    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH9

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        // Tokens
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = BEAN;
        tokens[1] = WETH;

        // Well Function
        IWellFunction cp2 = new ConstantProduct2();
        Call memory wellFunction = Call(address(cp2), new bytes(0));

        // Pump
        IPump mockPump = new MockPump();
        Call[] memory pumps = new Call[](1);
        pumps[0] = Call(address(mockPump), new bytes(0));

        // Well
        Well well = new Well(
            "BEAN:WETH Constant Product Well",
            "BEAN:WETH",
            tokens,
            wellFunction,
            pumps
        );

        console.log("Deployed CP2 at address: ", address(cp2));
        console.log("Deployed Pump at address: ", address(pumps[0].target));
        logger.logWell(well);
        
        vm.stopBroadcast();
    }
}