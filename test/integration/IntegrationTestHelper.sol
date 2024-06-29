// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console, stdError} from "forge-std/Test.sol";
import {Well, Call, IERC20} from "src/Well.sol";
import {Aquifer} from "src/Aquifer.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {MultiFlowPump} from "src/pumps/MultiFlowPump.sol";
import {LibContractInfo} from "src/libraries/LibContractInfo.sol";
import {Users} from "test/helpers/Users.sol";
import {TestHelper, Balances, ConstantProduct2} from "test/TestHelper.sol";
import {from18, to18} from "test/pumps/PumpHelpers.sol";

abstract contract IntegrationTestHelper is TestHelper {
    using LibContractInfo for address;

    function setupWell(IERC20[] memory _tokens, Well _well) internal returns (Well) {
        Call[] memory _pumps = new Call[](1);
        _pumps[0] = Call(address(new MultiFlowPump()), new bytes(0));

        return setupWell(_tokens, Call(address(new ConstantProduct2()), new bytes(0)), _pumps, _well);
    }

    function setupWell(
        IERC20[] memory _tokens,
        Call memory _function,
        Call[] memory _pumps,
        Well _well
    ) internal returns (Well) {
        wellFunction = _function;
        initUser();

        wellImplementation = deployWellImplementation();
        aquifer = new Aquifer();

        _well = encodeAndBoreWell(address(aquifer), wellImplementation, _tokens, wellFunction, _pumps, bytes32(0));

        // Mint mock tokens to user
        mintTokens(_tokens, user, initialLiquidity);
        mintTokens(_tokens, user2, initialLiquidity);

        approveMaxTokens(_tokens, user, address(_well));
        approveMaxTokens(_tokens, user2, address(_well));

        // Mint mock tokens to TestHelper
        mintTokens(_tokens, address(this), initialLiquidity * 5);
        approveMaxTokens(_tokens, address(this), address(_well));

        // Add initial liquidity from TestHelper
        addLiquidityEqualAmount(_tokens, address(this), initialLiquidity, Well(_well));

        return _well;
    }

    /// @dev mint mock tokens to each recipient
    function mintTokens(IERC20[] memory _tokens, address recipient, uint256 amount) internal {
        for (uint256 i; i < _tokens.length; i++) {
            deal(address(_tokens[i]), recipient, amount);
        }
    }

    /// @dev approve `spender` to use `owner` tokens
    function approveMaxTokens(IERC20[] memory _tokens, address owner, address spender) internal prank(owner) {
        for (uint256 i; i < _tokens.length; i++) {
            _tokens[i].approve(spender, type(uint256).max);
        }
    }

    /// @dev add the same `amount` of liquidity for all underlying tokens
    function addLiquidityEqualAmount(
        IERC20[] memory _tokens,
        address from,
        uint256 amount,
        Well _well
    ) internal prank(from) {
        uint256[] memory amounts = new uint256[](_tokens.length);
        for (uint256 i; i < _tokens.length; i++) {
            amounts[i] = amount;
        }
        _well.addLiquidity(amounts, 0, from, type(uint256).max);
    }

    enum ClipboardType {
        basic,
        singlePaste,
        MultiPaste
    }

    // clipboardHelper helps create the clipboard data for an AdvancePipeCall
    /// @param useEther Whether or not the call uses ether
    /// @param amount amount of ether to send
    /// @param _type What type the advanceCall is.
    /// @param returnDataIndex which previous advancedPipeCall
    // to copy from, ordered by execution.
    /// @param copyIndex what index to copy the data from.
    // this will copy 32 bytes from the index.
    /// @param pasteIndex what index to paste the copyData
    // into calldata
    function clipboardHelper(
        bool useEther,
        uint256 amount,
        ClipboardType _type,
        uint256 returnDataIndex,
        uint256 copyIndex,
        uint256 pasteIndex
    ) internal pure returns (bytes memory stuff) {
        uint256 clipboardData;
        clipboardData = clipboardData | (uint256(_type) << 248);

        clipboardData =
            clipboardData | (returnDataIndex << 160) | (((copyIndex * 32) + 32) << 80) | ((pasteIndex * 32) + 36);
        if (useEther) {
            // put 0x1 in second byte
            // shift left 30 bytes
            clipboardData = clipboardData | (1 << 240);
            return abi.encodePacked(clipboardData, amount);
        } else {
            return abi.encodePacked(clipboardData);
        }
    }
}
