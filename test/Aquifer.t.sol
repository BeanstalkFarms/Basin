// SPDX-License-Identifier: MIT
// forgefmt: disable-start

pragma solidity ^0.8.17;

import {TestHelper, Well, IERC20, console} from "test/TestHelper.sol";
import {MockStaticWell} from "mocks/wells/MockStaticWell.sol";
import {MockPump} from "mocks/pumps/MockPump.sol";
import {IWell, Call} from "src/interfaces/IWell.sol";
import {ConstantProduct} from "src/functions/ConstantProduct.sol";
import {LibClone} from "src/libraries/LibClone.sol";
import {LibWellConstructor} from "src/libraries/LibWellConstructor.sol";
import {Aquifer} from "src/Aquifer.sol";
import {MockInitFailWell} from "mocks/wells/MockInitFailWell.sol";

/// @dev Test the Aquifer's functionality in isolation. To avoid dependence on a
/// particular Well implementation, this test uses MockStaticWell which stores
/// Well components in immutable storage on construction rather than upon cloning.
/// Immutable data applied during cloning is verified separately.
contract AquiferTest is TestHelper {
    MockStaticWell mockWell;
    address initFailImplementation;

    bytes32 salt;
    bytes immutableData;
    bytes initFunctionCall;

    event BoreWell(
        address well, address implementation, IERC20[] tokens, Call wellFunction, Call[] pumps, bytes wellData
    );

    function setUp() public {
        tokens = deployMockTokens(2);
        aquifer = new Aquifer();
        
        // Setup static Well components
        wellFunction = Call(address(new ConstantProduct()), new bytes(0));
        pumps.push(Call(address(new MockPump()), new bytes(0)));
        wellData = bytes("hello world");
        
        // Deploy implementation. This contract will get cloned during {boreWell}.
        wellImplementation = address(new MockStaticWell(tokens, wellFunction, pumps, address(aquifer), wellData));
        initFailImplementation = address(new MockInitFailWell());

        // Shared clone data
        salt             = bytes32("Wells");
        immutableData    = abi.encodePacked(uint(6074));
        initFunctionCall = abi.encodeWithSignature("init(string,string)", "MockWell", "mWELL");
    }

    /// @dev Verify that the mock was deployed correctly.
    function test_constructed() public {
        _checkWell(MockStaticWell(wellImplementation), false);
    }

    //////////// DEPLOYMENT ////////////

    /// @dev Bore a Well with immutable data and salt.
    function test_bore_cloneDeterministic_withImmutableData() public {
        address destination = LibClone.predictDeterministicAddress(wellImplementation, immutableData, salt, address(aquifer));

        vm.expectEmit(true, true, true, true, address(aquifer));
        emit BoreWell(destination, wellImplementation, tokens, wellFunction, pumps, wellData);

        mockWell = MockStaticWell(aquifer.boreWell(
            wellImplementation,
            immutableData,
            initFunctionCall,
            salt
        ));

        _checkWell(mockWell, true);
        assertEq(uint(6074), mockWell.immutableDataFromClone(), "clone failed to set immutable data");
        assertEq(address(mockWell), destination, "deployment address mismatch");
    }

    /// @dev Bore a Well with immutable data, no salt.
    function test_bore_clone_withImmutableData() public {
        vm.expectEmit(true, true, true, false, address(aquifer));
        emit BoreWell(address(bytes20("UNKNOWN")), wellImplementation, tokens, wellFunction, pumps, wellData);

        mockWell = MockStaticWell(aquifer.boreWell(
            wellImplementation,
            immutableData,
            initFunctionCall,
            bytes32(0)
        ));

        _checkWell(mockWell, true);
        assertEq(uint(6074), mockWell.immutableDataFromClone(), "clone failed to set immutable data");
    }

    /// @dev Bore a Well with salt, no immutable data.
    function test_bore_cloneDeterministic() public {
        address destination = LibClone.predictDeterministicAddress(wellImplementation, salt, address(aquifer));

        vm.expectEmit(true, true, true, true, address(aquifer));
        emit BoreWell(destination, wellImplementation, tokens, wellFunction, pumps, wellData);

        mockWell = MockStaticWell(aquifer.boreWell(
            wellImplementation,
            "",
            initFunctionCall,
            salt
        ));

        _checkWell(mockWell, true);
        assertEq(address(mockWell), destination, "deployment address mismatch");
    }

    /// @dev Bore a Well with no salt, no immutable data.
    function test_bore_clone() public {
        vm.expectEmit(true, true, true, false, address(aquifer));
        emit BoreWell(address(bytes20("UNKNOWN")), wellImplementation, tokens, wellFunction, pumps, wellData);

        mockWell = MockStaticWell(aquifer.boreWell(
            wellImplementation,
            "",
            initFunctionCall,
            bytes32(0)
        ));

        _checkWell(mockWell, true);
    }

    /// @dev Revert if {aquifer()} function doesn't return the right Aquifer address after cloning.
    function test_bore_expectRevert_wrongAquifer() public {
        address wrongAquifer = address(bytes20("WRONG AQUIFER"));
        assertTrue(wrongAquifer != address(aquifer));

        wellImplementation = address(new MockStaticWell(tokens, wellFunction, pumps, wrongAquifer, wellData));
        vm.expectRevert("Aquifer: wrong aquifer address");
        aquifer.boreWell(
            wellImplementation,
            "",
            initFunctionCall,
            bytes32(0)
        );
    }

    /// @dev Revert if the Well implementation doesn't have the provided init function.
    /// FIXME: does fallback behavior affect this?
    function test_bore_expectRevert_missingInitFunction() public {
        vm.expectRevert("Aquifer: well init");
        aquifer.boreWell(
            wellImplementation,
            "",
            abi.encodeWithSignature("doesNotExist()"),
            bytes32(0)
        );
    }

    /// @dev Reversion during init propagates the revert message if one is returned. 
    /// See {MockInitFailWell.sol}
    function test_bore_initRevert_withMessage() public {
        vm.expectRevert("Aquifer: Well Init (Well: fail message)");
        aquifer.boreWell(
            initFailImplementation,
            "",
            abi.encodeWithSignature("initMessage()"),
            bytes32(0)
        );
    }


    /// @dev Reversion during init uses default message if no revert message is returned. 
    /// See {MockInitFailWell.sol}
    function test_bore_initRevert_noMessage() public {
        vm.expectRevert("Aquifer: well init");
        aquifer.boreWell(
            initFailImplementation,
            "",
            abi.encodeWithSignature("initNoMessage()"),
            bytes32(0)
        );
    }

    function _checkWell(MockStaticWell _well, bool isInitialized) private {
        IERC20[] memory _tokens = _well.tokens();
        Call[] memory _pumps = _well.pumps();
    
        assertEq(_tokens, tokens);
        assertEq(_pumps, pumps);
        assertEq(_well.wellFunction(), wellFunction);
        assertEq(_well.aquifer(), address(aquifer));
        assertEq(_well.wellData(), wellData);
        
        if (isInitialized) {
            assertEq(_well.name(), "MockWell", "name mismatch");
            assertEq(_well.symbol(), "mWELL", "symbol mismatch");
            assertEq(aquifer.wellImplementation(address(_well)), wellImplementation, "implementation mismatch");
        }
    }
}
