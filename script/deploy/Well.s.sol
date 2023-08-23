// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console2} from "forge-std/console2.sol";
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";

import {WellDeployer} from "script/helpers/WellDeployer.sol";
import {logger} from "script/deploy/helpers/Logger.sol";
import {MockPump} from "mocks/pumps/MockPump.sol";

import {Well, Call, IWellFunction, IPump, IERC20} from "src/Well.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";
import {Aquifer} from "src/Aquifer.sol";

/**
 * @dev Deploys a BEAN:WETH ConstantProduct2 Well. Intended for testing.
 */
contract DeployWell is Script, WellDeployer {
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

        address aquifer = address(new Aquifer());

        address wellImplementation = address(new Well());

        // Well
        Well well = encodeAndBoreWell(aquifer, wellImplementation, tokens, wellFunction, pumps, bytes32(0));

        console.log("Deployed CP2 at address: ", address(cp2));
        console.log("Deployed Pump at address: ", address(pumps[0].target));
        logger.logWell(well);

        vm.stopBroadcast();
    }
}
