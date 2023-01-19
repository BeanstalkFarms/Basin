// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Well} from "../src/wells/Well.sol";
import "src/interfaces/IWell.sol";
import {MockPump} from "../mocks/pumps/MockPump.sol";
import {ConstantProduct2} from "../src/wellFunctions/ConstantProduct2.sol";
import {SafeERC20, IERC20} from "oz/token/ERC20/utils/SafeERC20.sol";


// Script to deploy a BEAN-ETH {Well}, 
// with a constant product pricing function, 
// and a MockPump.
// @dev recommended to deploy a well via an aquifer.
contract WellScript is Script {
    using SafeERC20 for IERC20;
    
    function run() external {
        bytes memory data = "";
        address BEAN = 0xBEA0000029AD1c77D3d5D23Ba2D8893dB9d1Efab;
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        uint256 deployerPrivateKey = vm.envUint("ANVILPK");
        vm.startBroadcast(deployerPrivateKey);
        string memory name = "TESTWELL";
        string memory symbol = "TSTw";

        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = IERC20(BEAN);
        tokens[1] = IERC20(WETH);
        // deploy pump/wellFunction first 
        MockPump mockPump = new MockPump();
        ConstantProduct2 cp2 = new ConstantProduct2();
        // create calls
        Call[] memory mockPumpCall = new Call[](1);
        mockPumpCall[0].target = address(mockPump);
        mockPumpCall[0].data = data;
        
        Call memory cp2Call;
        cp2Call.target = address(cp2);
        cp2Call.data = data;

        //deploy well
        Well well = new Well(
            name,
            symbol,
            tokens,
            cp2Call,
            mockPumpCall
        );

        vm.stopBroadcast();
    }
}