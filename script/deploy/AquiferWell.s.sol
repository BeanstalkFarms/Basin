// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {SafeERC20, IERC20} from "oz/token/ERC20/utils/SafeERC20.sol";

import {IWell, Call} from "src/interfaces/IWell.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {IPump} from "src/interfaces/pumps/IPump.sol";

import {logger} from "script/deploy/helpers/Logger.sol";
import {MockToken} from "mocks/tokens/MockToken.sol";
import {MockPump} from "mocks/pumps/MockPump.sol";

import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";
import {Well} from "src/Well.sol";
import {Aquifer} from "src/Aquifer.sol";

import {WellDeployer} from "script/helpers/WellDeployer.sol";

/**
 * @dev Script to deploy a BEAN-ETH {Well} with a ConstantProduct2 pricing function
 * and MockPump via an Aquifer.
 */
contract DeployAquiferWell is Script, WellDeployer {
    using SafeERC20 for IERC20;

    IERC20 constant BEAN = IERC20(0xBEA0000029AD1c77D3d5D23Ba2D8893dB9d1Efab);
    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH9

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Tokens
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = BEAN;
        tokens[1] = WETH;

        // Deploy Aquifer
        address aquifer = address(new Aquifer());

        // Well Function
        IWellFunction cp2 = new ConstantProduct2();
        Call memory wellFunction = Call(address(cp2), new bytes(0));

        // Pump
        IPump mockPump = new MockPump();
        Call[] memory pumps = new Call[](1);
        pumps[0] = Call(address(mockPump), new bytes(0));

        // Well implementation
        address wellImplementation = address(new Well());

        //bore well
        Well well = encodeAndBoreWell(aquifer, wellImplementation, tokens, wellFunction, pumps, bytes32(0));

        console.log("Deployed CP2 at address: ", address(cp2));
        console.log("Deployed Pump at address: ", address(pumps[0].target));
        logger.logWell(well);

        vm.stopBroadcast();
    }
}
