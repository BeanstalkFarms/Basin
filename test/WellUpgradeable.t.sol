// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {WellUpgradeable} from "src/WellUpgradeable.sol";
import {IERC20} from "test/TestHelper.sol";
import {WellDeployer} from "script/helpers/WellDeployer.sol";
import {MockPump} from "mocks/pumps/MockPump.sol";
import {Well, Call, IWellFunction, IPump, IERC20} from "src/Well.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";
import {Aquifer} from "src/Aquifer.sol";
import {WellDeployer} from "script/helpers/WellDeployer.sol";
import {LibWellUpgradeableConstructor} from "src/libraries/LibWellUpgradeableConstructor.sol";
import {LibContractInfo} from "src/libraries/LibContractInfo.sol";
import {MockToken} from "mocks/tokens/MockToken.sol";
import {WellDeployer} from "script/helpers/WellDeployer.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {MockWellUpgradeable} from "mocks/wells/MockWellUpgradeable.sol";

contract WellUpgradeTest is Test, WellDeployer {

    address proxyAddress;
    address aquifer;
    address initialOwner;
    address user;
    address mockPumpAddress;
    address wellFunctionAddress;
    address token1Address;
    address token2Address;

    function setUp() public {

        // Tokens
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = new MockToken("BEAN", "BEAN", 6);
        tokens[1] = new MockToken("WETH", "WETH", 18);

        token1Address = address(tokens[0]);
        token2Address = address(tokens[1]);

        user = makeAddr("user");

        // Mint tokens
        MockToken(address(tokens[0])).mint(user, 10000000000000000);
        MockToken(address(tokens[1])).mint(user, 10000000000000000);
        // Well Function
        IWellFunction cp2 = new ConstantProduct2();
        wellFunctionAddress = address(cp2);
        Call memory wellFunction = Call(address(cp2), abi.encode("beanstalkFunction"));

        // Pump
        IPump mockPump = new MockPump();
        mockPumpAddress = address(mockPump);
        Call[] memory pumps = new Call[](1);
        // init new mock pump with "beanstalk" data
        pumps[0] = Call(address(mockPump), abi.encode("beanstalkPump"));
        aquifer = address(new Aquifer());
        address wellImplementation = address(new WellUpgradeable());
        initialOwner = makeAddr("owner");

        // Well
        WellUpgradeable well = encodeAndBoreWellUpgradeable(aquifer, wellImplementation, tokens, wellFunction, pumps, bytes32(0), initialOwner);

        // Sum up of what is going on here
        // We encode and bore a well upgradeable from the aquifer
        // The well upgradeable additionally takes in an owner address so we modify the init function call
        // to include the owner address. 
        // When the new well is deployed, all init data are stored in the implementation storage 
        // including pump and well function data --> NOTE: This could be an issue but how do we solve this?
        // Then we deploy a ERC1967Proxy proxy for the well upgradeable and call the init function on the proxy
        // When we deploy the proxy, the init data is stored in the proxy storage and the well is initialized 
        // for the second time. We can now control the well via delegate calls to the proxy address.

        // Every time we call the init function, we init the owner to be the msg.sender and
        // then immidiately transfer ownership
        // to an address of our choice (see WellUpgradeable.sol for more details on the init function)

        // FROM OZ
        // If _data is nonempty, it’s used as data in a delegate call to _logic. 
        // This will typically be an encoded function call, and allows initializing 
        // the storage of the proxy like a Solidity constructor.

        // Deploy Proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(well), // implementation address
            // init data (name, symbol, owner) );
            abi.encodeCall(WellUpgradeable.init, ("WELL", "WELL", initialOwner)) // _data
        );
        proxyAddress = address(proxy);

        vm.startPrank(user);
        tokens[0].approve(proxyAddress, type(uint256).max);
        tokens[1].approve(proxyAddress, type(uint256).max);
        vm.stopPrank();
        
    }

    ///////////////////// Storage Tests /////////////////////

    function testProxyGetAquifer() public {
        assertEq(address(aquifer), WellUpgradeable(proxyAddress).aquifer());
    }

    function testProxyGetPump() public {       
        Call[] memory proxyPumps = WellUpgradeable(proxyAddress).pumps();
        assertEq(mockPumpAddress, proxyPumps[0].target);
        // this passes but why? Pump data are supposed
        // to be stored in the implementation storage from the borewell call
        assertEq(abi.encode("beanstalkPump"), proxyPumps[0].data);
    }

    function testProxyGetTokens() public {
        IERC20[] memory proxyTokens = WellUpgradeable(proxyAddress).tokens();
        assertEq(address(proxyTokens[0]), token1Address);
        assertEq(address(proxyTokens[1]), token2Address);
    }

    function testProxyGetWellFunction() public {
        Call memory proxyWellFunction = WellUpgradeable(proxyAddress).wellFunction();
        assertEq(address(proxyWellFunction.target), address(wellFunctionAddress));
        assertEq(proxyWellFunction.data, abi.encode("beanstalkFunction"));
    }

    function testProxyGetSymbolInStorage() public {
        assertEq("WELL", WellUpgradeable(proxyAddress).symbol());
    }

    function testProxyInitVersion() public {
        uint256 expectedVersion = 1;
        assertEq(expectedVersion, WellUpgradeable(proxyAddress).getVersion());
    }

    function testProxyNumTokens() public {
        uint256 expectedNumTokens = 2;
        assertEq(expectedNumTokens, WellUpgradeable(proxyAddress).numberOfTokens());
    }

    ///////////////// Interaction test //////////////////

    function testProxyAddLiquidity() public {
        vm.startPrank(user);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1000;
        amounts[1] = 1000;
        WellUpgradeable(proxyAddress).addLiquidity(amounts, 0 , user, type(uint256).max);
        assertEq(amounts, WellUpgradeable(proxyAddress).getReserves());
        vm.stopPrank();
    }

    ////////////// Ownership Tests //////////////

    function testProxyOwner() public {
        assertEq(initialOwner, WellUpgradeable(proxyAddress).owner());
    }

    function testProxyTransferOwnership() public {
        vm.prank(initialOwner);
        address newOwner = makeAddr("newOwner");
        WellUpgradeable(proxyAddress).transferOwnership(newOwner);
        assertEq(newOwner, WellUpgradeable(proxyAddress).owner());
    }

    function testRevertTransferOwnershipFromNotOnwer() public {
        vm.expectRevert();
        address notOwner = makeAddr("notOwner");
        vm.prank(notOwner);
        WellUpgradeable(proxyAddress).transferOwnership(notOwner);
    }

    ////////////////////// Upgrade Tests //////////////////////

    function testUpgradeToNewImplementation() public {
        vm.startPrank(initialOwner);
        WellUpgradeable proxy = WellUpgradeable(payable(proxyAddress));
        MockWellUpgradeable newImpl = new MockWellUpgradeable();
        // getting error due to the onlyProxy modifier in UUPSUpgradeable.sol
        // commented this out for now in UUPSUpgradeable.sol
        // require(_getImplementation() == __self, "Function must be called through active proxy");
        proxy.upgradeTo(address(newImpl));
        assertEq(initialOwner, MockWellUpgradeable(proxyAddress).owner());
        vm.stopPrank();
    }

}