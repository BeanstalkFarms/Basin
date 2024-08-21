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
    address wellAddress;
    address wellImplementation;
    IERC20[] tokens = new IERC20[](2);

    function setUp() public {
        // Tokens
        IERC20 token0 = new MockToken("BEAN", "BEAN", 6);
        IERC20 token1 = new MockToken("WETH", "WETH", 18);
        tokens[0] = token0;
        tokens[1] = token1;

        token1Address = address(tokens[0]);
        vm.label(token1Address, "token1");
        token2Address = address(tokens[1]);
        vm.label(token2Address, "token2");

        user = makeAddr("user");

        // Mint tokens
        MockToken(address(tokens[0])).mint(user, 10_000_000_000_000_000);
        MockToken(address(tokens[1])).mint(user, 10_000_000_000_000_000);
        // Well Function
        IWellFunction cp2 = new ConstantProduct2();
        vm.label(address(cp2), "CP2");
        wellFunctionAddress = address(cp2);
        Call memory wellFunction = Call(address(cp2), abi.encode("beanstalkFunction"));

        // Pump
        IPump mockPump = new MockPump();
        mockPumpAddress = address(mockPump);
        vm.label(mockPumpAddress, "mockPump");
        Call[] memory pumps = new Call[](1);
        // init new mock pump with "beanstalk" data
        pumps[0] = Call(address(mockPump), abi.encode("beanstalkPump"));
        aquifer = address(new Aquifer());
        vm.label(aquifer, "aquifer");
        wellImplementation = address(new WellUpgradeable());
        vm.label(wellImplementation, "wellImplementation");
        initialOwner = makeAddr("owner");

        // Well
        WellUpgradeable well =
            encodeAndBoreWellUpgradeable(aquifer, wellImplementation, tokens, wellFunction, pumps, bytes32(0));
        wellAddress = address(well);
        vm.label(wellAddress, "upgradeableWell");
        // Sum up of what is going on here
        // We encode and bore a well upgradeable from the aquifer
        // The well upgradeable additionally takes in an owner address so we modify the init function call
        // to include the owner address.
        // When the new well is deployed, all init data are stored in the implementation storage
        // including pump and well function data
        // Then we deploy a ERC1967Proxy proxy for the well upgradeable and call the init function on the proxy
        // When we deploy the proxy, the init data is stored in the proxy storage and the well is initialized
        // for the second time. We can now control the well via delegate calls to the proxy address.

        // Every time we call the init function, we init the owner to be the msg.sender
        // (see WellUpgradeable.sol for more details on the init function)

        // FROM OZ
        // If _data is nonempty, it’s used as data in a delegate call to _logic.
        // This will typically be an encoded function call, and allows initializing
        // the storage of the proxy like a Solidity constructor.

        // Deploy Proxy
        vm.startPrank(initialOwner);
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(well), // implementation address
            LibWellUpgradeableConstructor.encodeWellInitFunctionCall(tokens, wellFunction) // init data
        );
        vm.stopPrank();
        proxyAddress = address(proxy);
        vm.label(proxyAddress, "proxyAddress");

        vm.startPrank(user);
        tokens[0].approve(wellAddress, type(uint256).max);
        tokens[1].approve(wellAddress, type(uint256).max);
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
        assertEq("BEANWETHCP2uw", WellUpgradeable(proxyAddress).symbol());
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
        WellUpgradeable(wellAddress).addLiquidity(amounts, 0, user, type(uint256).max);
        WellUpgradeable(proxyAddress).addLiquidity(amounts, 0, user, type(uint256).max);
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
        address notOwner = makeAddr("notOwner");
        vm.prank(notOwner);
        vm.expectRevert();
        WellUpgradeable(proxyAddress).transferOwnership(notOwner);
    }

    ////////////////////// Upgrade Tests //////////////////////

    function testUpgradeToNewImplementation() public {
        Call memory wellFunction = Call(wellFunctionAddress, abi.encode("2"));
        Call[] memory pumps = new Call[](1);
        pumps[0] = Call(mockPumpAddress, abi.encode("2"));
        // create new mock Well Implementation:
        address wellImpl = address(new MockWellUpgradeable());
        WellUpgradeable well2 =
            encodeAndBoreWellUpgradeable(aquifer, wellImpl, tokens, wellFunction, pumps, bytes32(abi.encode("2")));
        vm.label(address(well2), "upgradeableWell2");
        vm.startPrank(initialOwner);
        WellUpgradeable proxy = WellUpgradeable(payable(proxyAddress));
        proxy.upgradeTo(address(well2));
        assertEq(initialOwner, MockWellUpgradeable(proxyAddress).owner());
        // verify proxy was upgraded.
        assertEq(address(well2), MockWellUpgradeable(proxyAddress).getImplementation());
        assertEq(1, MockWellUpgradeable(proxyAddress).getVersion());
        assertEq(100, MockWellUpgradeable(proxyAddress).getVersion(100));
        vm.stopPrank();
    }

    ///////////////// Access Control ////////////////////

    function testUpgradeToNewImplementationAccessControl() public {
        Call memory wellFunction = Call(wellFunctionAddress, abi.encode("2"));
        Call[] memory pumps = new Call[](1);
        pumps[0] = Call(mockPumpAddress, abi.encode("2"));
        // create new mock Well Implementation:
        address wellImpl = address(new MockWellUpgradeable());
        WellUpgradeable well2 =
            encodeAndBoreWellUpgradeable(aquifer, wellImpl, tokens, wellFunction, pumps, bytes32(abi.encode("2")));
        vm.label(address(well2), "upgradeableWell2");
        // set caller to not be the owner
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        WellUpgradeable proxy = WellUpgradeable(payable(proxyAddress));
        // expect revert
        vm.expectRevert("Ownable: caller is not the owner");
        proxy.upgradeTo(address(well2));
        vm.stopPrank();
    }

    ///////////////////// Token Check //////////////////////

    function testUpgradeToNewImplementationDiffTokens() public {
        // create 2 new tokens with new addresses
        IERC20[] memory newTokens = new IERC20[](2);
        newTokens[0] = new MockToken("WBTC", "WBTC", 6);
        newTokens[1] = new MockToken("WETH2", "WETH2", 18);
        Call memory wellFunction = Call(wellFunctionAddress, abi.encode("2"));
        Call[] memory pumps = new Call[](1);
        pumps[0] = Call(mockPumpAddress, abi.encode("2"));
        // create new mock Well Implementation:
        address wellImpl = address(new MockWellUpgradeable());
        // bore new well with the different tokens
        WellUpgradeable well2 =
            encodeAndBoreWellUpgradeable(aquifer, wellImpl, newTokens, wellFunction, pumps, bytes32(abi.encode("2")));
        vm.label(address(well2), "upgradeableWell2");
        vm.startPrank(initialOwner);
        WellUpgradeable proxy = WellUpgradeable(payable(proxyAddress));
        // expect revert since new well uses different tokens
        vm.expectRevert("New well must use the same tokens in the same order");
        proxy.upgradeTo(address(well2));
        vm.stopPrank();
    }

    function testUpgradeToNewImplementationDiffTokenOrder() public {
        // create 2 new tokens with new addresses
        IERC20[] memory newTokens = new IERC20[](2);
        newTokens[0] = tokens[1];
        newTokens[1] = tokens[0];
        Call memory wellFunction = Call(wellFunctionAddress, abi.encode("2"));
        Call[] memory pumps = new Call[](1);
        pumps[0] = Call(mockPumpAddress, abi.encode("2"));
        // create new mock Well Implementation:
        address wellImpl = address(new MockWellUpgradeable());
        // bore new well with the different tokens
        WellUpgradeable well2 =
            encodeAndBoreWellUpgradeable(aquifer, wellImpl, newTokens, wellFunction, pumps, bytes32(abi.encode("2")));
        vm.label(address(well2), "upgradeableWell2");
        vm.startPrank(initialOwner);
        WellUpgradeable proxy = WellUpgradeable(payable(proxyAddress));
        // expect revert since new well uses different tokens
        vm.expectRevert("New well must use the same tokens in the same order");
        proxy.upgradeTo(address(well2));
        vm.stopPrank();
    }
}
