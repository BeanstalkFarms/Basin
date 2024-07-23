//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "test/integration/IntegrationTestHelper.sol";

/**
 * @title IPipeline
 * @author Brendan
 * @notice Pipeline Interface – Pipeline creates a sandbox to execute any series of function calls on any series of protocols through \term{Pipe} functions.
 * Any assets left in Pipeline between transactions can be transferred out by any account.
 * Users Pipe a series of PipeCalls that each execute a function call to another protocol through Pipeline.
 *
 */

// PipeCalls specify a function call to be executed by Pipeline.
// Pipeline supports 2 types of PipeCalls: PipeCall and AdvancedPipeCall.

// PipeCall makes a function call with a static target address and callData.
struct PipeCall {
    address target;
    bytes data;
}

// AdvancedPipeCall makes a function call with a static target address and both static and dynamic callData.
// AdvancedPipeCalls support sending Ether in calls.
// [ PipeCall Type | Send Ether Flag | PipeCall Type data | Ether Value (only if flag == 1)]
// [ 1 byte        | 1 byte          | n bytes        | 0 or 32 bytes                      ]
// See LibFunction.useClipboard for more details.
struct AdvancedPipeCall {
    address target;
    bytes callData;
    bytes clipboard;
}

interface IPipeline {
    function pipe(PipeCall calldata p) external payable returns (bytes memory result);

    function multiPipe(PipeCall[] calldata pipes) external payable returns (bytes[] memory results);

    function advancedPipe(AdvancedPipeCall[] calldata pipes) external payable returns (bytes[] memory results);
}

interface IDepot {
    function advancedPipe(
        AdvancedPipeCall[] calldata pipes,
        uint256 value
    ) external payable returns (bytes[] memory results);

    function farm(bytes[] calldata data) external payable returns (bytes[] memory results);

    function transferToken(
        IERC20 token,
        address recipient,
        uint256 amount,
        From fromMode,
        To toMode
    ) external payable;
}

enum From {
    EXTERNAL,
    INTERNAL,
    EXTERNAL_INTERNAL,
    INTERNAL_TOLERANT
}

enum To {
    EXTERNAL,
    INTERNAL
}

interface IBeanstalk {
    function transferInternalTokenFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount,
        To toMode
    ) external payable;

    function permitToken(
        address owner,
        address spender,
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function transferDeposit(
        address sender,
        address recipient,
        address token,
        uint32 season,
        uint256 amount
    ) external payable returns (uint256 bdv);

    function transferDeposits(
        address sender,
        address recipient,
        address token,
        uint32[] calldata seasons,
        uint256[] calldata amounts
    ) external payable returns (uint256[] memory bdvs);

    function permitDeposits(
        address owner,
        address spender,
        address[] calldata tokens,
        uint256[] calldata values,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function permitDeposit(
        address owner,
        address spender,
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}
