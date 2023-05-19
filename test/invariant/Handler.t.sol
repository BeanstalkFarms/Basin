// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {TestHelper, IERC20, Call, Balances} from "test/TestHelper.sol";
import {ConstantProduct2, IWellFunction} from "src/functions/ConstantProduct2.sol";
import {Snapshot, AddLiquidityAction, RemoveLiquidityAction, LiquidityHelper} from "test/LiquidityHelper.sol";
import {MockToken} from "mocks/tokens/MockToken.sol";
import {Well} from "src/Well.sol";
import {Invariants} from "./Invariants.t.sol";
import "forge-std/Test.sol";
import {EnumerableSet} from "oz/utils/structs/EnumerableSet.sol";

/// @dev The handler is the set of valid actions that can be performed during an invariant test run.
/// @dev These include adding and removing liquidity, transfers, swaps, shifts, etc.
contract Handler is Test {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev The deployed well to interact with
    Well internal s_well;

    // GHOST VARIABLES

    /// @dev The set of LPs that hold LP tokens
    EnumerableSet.AddressSet internal s_LPs;

    /// @dev LPs that have approved other addresses to spend their LP tokens
    EnumerableSet.AddressSet internal s_approvedBy;

    /// @dev Mapping to track the approvals from approvedBy addresses to approvedTo addresses
    mapping(address => EnumerableSet.AddressSet) internal s_approvedTo;

    // OUTPUT VARS - used to print a summary of calls and reverts during certain actions

    /// @dev The number of calls to `swapTo`
    uint internal s_swapToCalls;
    /// @dev The number of reverts on calling `swapTo`
    uint internal s_swapToFails;

    /// @dev The number of calls to `removeLiquidityOneToken`
    uint internal s_removeLiquidityOneTokenCalls;
    /// @dev The number of reverts on calling `removeLiquidityOneToken`
    uint internal s_removeLiquidityOneTokenFails;

    /// @dev The number of calls to `removeLiquidityImbalanced`
    uint internal s_removeLiquidityImbalancedCalls;
    /// @dev The number of reverts on calling `removeLiquidityImbalanced`
    uint internal s_removeLiquidityImbalancedFails;

    /// @dev The number of calls to `getShiftOut`
    uint internal s_getShiftOutCalls;
    /// @dev The number of reverts on calling `getShiftOut`
    uint internal s_getShiftOutFails;
    /// @dev The number of calls to `shift`
    uint internal s_shiftCalls;
    /// @dev The number of reverts on callling `shift`
    uint internal s_shiftFails;

    constructor(Well well) {
        s_LPs.add(msg.sender); // TestHelper adds initial liquidity
        s_well = well;
    }

    // IWELL
    // =====

    /// @dev swapFrom
    function swapFrom(uint addressSeed, uint tokenInIndex, uint amountIn) public {
        // bound address seed
        address msgSender = _seedToAddress(addressSeed);
        changePrank(msgSender);
        // bound token index
        tokenInIndex = bound(tokenInIndex, 0, 1);
        uint tokenOutIndex = tokenInIndex == 0 ? 1 : 0;
        // bound amount in
        amountIn = bound(amountIn, 1, type(uint96).max);

        // mint tokens to the sender
        IERC20[] memory mockTokens = s_well.tokens();
        MockToken(address(mockTokens[tokenInIndex])).mint(msgSender, amountIn);
        // approve the well
        mockTokens[tokenInIndex].approve(address(s_well), amountIn);

        // swap
        uint minAmountOut = s_well.getSwapOut(mockTokens[tokenInIndex], mockTokens[tokenOutIndex], amountIn);
        s_well.swapFrom(
            mockTokens[tokenInIndex], mockTokens[tokenOutIndex], amountIn, minAmountOut, msgSender, block.timestamp
        );
    }

    /// @dev swapFromFeeOnTransfer - This won't actually take a fee on transfer, because in the current
    /// setup, we use non-fee taking tokens.
    function swapFromFeeOnTransfer(uint addressSeed, uint tokenInIndex, uint amountIn) public {
        // bound address seed
        address msgSender = _seedToAddress(addressSeed);
        changePrank(msgSender);
        // bound token index
        tokenInIndex = bound(tokenInIndex, 0, 1);
        uint tokenOutIndex = tokenInIndex == 0 ? 1 : 0;
        // bound amount in
        amountIn = bound(amountIn, 1, type(uint96).max);

        // mint tokens to the sender
        IERC20[] memory mockTokens = s_well.tokens();
        MockToken(address(mockTokens[tokenInIndex])).mint(msgSender, amountIn);
        // approve the well
        mockTokens[tokenInIndex].approve(address(s_well), amountIn);

        // swap
        uint minAmountOut = s_well.getSwapOut(mockTokens[tokenInIndex], mockTokens[tokenOutIndex], amountIn);
        s_well.swapFromFeeOnTransfer(
            mockTokens[tokenInIndex], mockTokens[tokenOutIndex], amountIn, minAmountOut, msgSender, block.timestamp
        );
    }

    /// @dev swapTo
    function swapTo(uint addressSeed, uint tokenOutIndex, uint amountOut) public {
        s_swapToCalls++;
        // bound address seed
        address msgSender = _seedToAddress(addressSeed);
        changePrank(msgSender);
        // bound token index
        tokenOutIndex = bound(tokenOutIndex, 0, 1);
        uint tokenInIndex = tokenOutIndex == 0 ? 1 : 0;
        // bound amount out
        amountOut = bound(amountOut, 1, type(uint96).max);

        // mint tokens to the sender
        IERC20[] memory mockTokens = s_well.tokens();
        // get amount in
        try s_well.getSwapIn(mockTokens[tokenInIndex], mockTokens[tokenOutIndex], amountOut) returns (uint amountIn) {
            // mint the correct amount in to the sender
            MockToken(address(mockTokens[tokenInIndex])).mint(msgSender, amountIn);
            // approve the well
            mockTokens[tokenInIndex].approve(address(s_well), amountIn);
            // swap
            s_well.swapTo(
                mockTokens[tokenInIndex], mockTokens[tokenOutIndex], amountIn, amountOut, msgSender, block.timestamp
            );
        } catch {
            s_swapToFails++;
        }
    }

    /// @dev shift
    function shift(uint addressSeed) public {
        // bound address seed
        address msgSender = _seedToAddress(addressSeed);
        changePrank(msgSender);
        IERC20[] memory mockTokens = s_well.tokens();
        for (uint i = 0; i < mockTokens.length; i++) {
            s_getShiftOutCalls++;
            try s_well.getShiftOut(mockTokens[i]) returns (uint amountOut) {
                if (amountOut > 0) {
                    // shift token0
                    s_shiftCalls++;
                    try s_well.shift(mockTokens[i], amountOut, msgSender) {
                        console.log("shifted");
                    } catch {
                        s_shiftFails++;
                    }
                    return;
                }
            } catch {
                s_getShiftOutFails++;
            }
        }
    }

    /// @dev addLiquidity
    function addLiquidity(uint addressSeed, uint token0AmountIn, uint token1AmountIn) public {
        // bound address seed
        address msgSender = _seedToAddress(addressSeed);
        changePrank(msgSender);
        // bound token amounts
        token0AmountIn = bound(token0AmountIn, 1, type(uint96).max);
        token1AmountIn = bound(token1AmountIn, 1, type(uint96).max);

        uint[] memory tokenAmountsIn = new uint[](2);
        tokenAmountsIn[0] = token0AmountIn;
        tokenAmountsIn[1] = token1AmountIn;
        // mint tokens to the sender
        IERC20[] memory mockTokens = s_well.tokens();
        for (uint i = 0; i < mockTokens.length; i++) {
            MockToken(address(mockTokens[i])).mint(msgSender, tokenAmountsIn[i]);
            // approve the well
            mockTokens[i].approve(address(s_well), tokenAmountsIn[i]);
        }

        // add liquidity
        uint minLpAmountOut = s_well.getAddLiquidityOut(tokenAmountsIn);
        uint lpAmountOut = s_well.addLiquidity(tokenAmountsIn, minLpAmountOut, msgSender, block.timestamp);
        assertGe(lpAmountOut, minLpAmountOut);
        // add the LP to the set
        s_LPs.add(msgSender);
    }

    /// @dev addLiquidityFeeOnTransfer - This won't actually take a fee on transfer, because in the current
    /// setup, we use non-fee taking tokens.
    function addLiquidityFeeOnTransfer(uint addressSeed, uint token0AmountIn, uint token1AmountIn) public {
        // bound address seed
        address msgSender = _seedToAddress(addressSeed);
        changePrank(msgSender);
        // bound token amounts
        token0AmountIn = bound(token0AmountIn, 1, type(uint96).max);
        token1AmountIn = bound(token1AmountIn, 1, type(uint96).max);

        uint[] memory tokenAmountsIn = new uint[](2);
        tokenAmountsIn[0] = token0AmountIn;
        tokenAmountsIn[1] = token1AmountIn;
        // mint tokens to the sender
        IERC20[] memory mockTokens = s_well.tokens();
        for (uint i = 0; i < mockTokens.length; i++) {
            MockToken(address(mockTokens[i])).mint(msgSender, tokenAmountsIn[i]);
            // approve the well
            mockTokens[i].approve(address(s_well), tokenAmountsIn[i]);
        }

        // add liquidity
        uint minLpAmountOut = s_well.getAddLiquidityOut(tokenAmountsIn);
        uint lpAmountOut = s_well.addLiquidityFeeOnTransfer(tokenAmountsIn, minLpAmountOut, msgSender, block.timestamp);
        assertGe(lpAmountOut, minLpAmountOut);

        // add the LP to the set
        s_LPs.add(msgSender);
    }

    /// @dev removeLiquidity
    function removeLiquidity(uint addressIndex, uint lpAmountIn) public {
        if (s_LPs.length() == 0) {
            return;
        }
        // bound address index
        address msgSender = _indexToLpAddress(addressIndex);
        changePrank(msgSender);
        // bound lp amount
        lpAmountIn = bound(lpAmountIn, 0, s_well.balanceOf(msgSender));

        // remove liquidity
        uint[] memory minTokenAmountsOut = s_well.getRemoveLiquidityOut(lpAmountIn);
        uint[] memory tokenAmountsOut =
            s_well.removeLiquidity(lpAmountIn, minTokenAmountsOut, msgSender, block.timestamp);

        assertGe(tokenAmountsOut[0], minTokenAmountsOut[0]);
        assertGe(tokenAmountsOut[1], minTokenAmountsOut[1]);

        // remove the LP from the set if they have no more LP
        if (s_well.balanceOf(msgSender) == 0) {
            s_LPs.remove(msgSender);
        }
    }

    /// @dev removeLiquidityOneToken
    function removeLiquidityOneToken(uint addressIndex, uint tokenIndex, uint lpAmountIn) public {
        if (s_LPs.length() == 0) {
            return;
        }
        s_removeLiquidityOneTokenCalls++;
        // bound address index
        address msgSender = _indexToLpAddress(addressIndex);
        changePrank(msgSender);
        // bound token index
        tokenIndex = bound(tokenIndex, 0, 1);
        IERC20 token = s_well.tokens()[tokenIndex];
        // bound lp amount
        lpAmountIn = bound(lpAmountIn, 0, s_well.balanceOf(msgSender));

        // remove liquidity
        try s_well.getRemoveLiquidityOneTokenOut(lpAmountIn, token) returns (uint minTokenAmountOut) {
            s_well.removeLiquidityOneToken(lpAmountIn, token, minTokenAmountOut, msgSender, block.timestamp);
            // remove the LP from the set if they have no more LP
            if (s_well.balanceOf(msgSender) == 0) {
                s_LPs.remove(msgSender);
            }
        } catch {
            s_removeLiquidityOneTokenFails++;
        }
    }

    /// @dev removeLiquidityImbalanced
    function removeLiquidityImbalanced(uint addressIndex, uint token0AmountOut, uint token1AmountOut) public {
        if (s_LPs.length() == 0) {
            return;
        }
        s_removeLiquidityImbalancedCalls++;
        // bound address index
        address msgSender = _indexToLpAddress(addressIndex);
        changePrank(msgSender);
        // bound token amounts
        token0AmountOut = bound(token0AmountOut, 0, type(uint96).max);
        token1AmountOut = bound(token1AmountOut, 0, type(uint96).max);

        uint[] memory tokenAmountsOut = new uint[](2);
        tokenAmountsOut[0] = token0AmountOut;
        tokenAmountsOut[1] = token1AmountOut;

        // remove liquidity
        try s_well.getRemoveLiquidityImbalancedIn(tokenAmountsOut) returns (uint lpAmountIn) {
            try s_well.removeLiquidityImbalanced(lpAmountIn, tokenAmountsOut, msgSender, block.timestamp) {}
            catch {
                s_removeLiquidityImbalancedFails++;
            }
        } catch {
            s_removeLiquidityImbalancedFails++;
        }
        // remove the LP from the set if they have no more LP
        if (s_well.balanceOf(msgSender) == 0) {
            s_LPs.remove(msgSender);
        }
    }

    /// @dev sync
    function sync() public {
        s_well.sync();
    }

    /// @dev skim
    function skim() public {
        s_well.skim(address(this));
    }

    // IERC20
    // ======

    /// @dev transfer
    function transferLP(uint addressFromIndex, uint addressToSeed, uint amount) public {
        if (s_LPs.length() == 0) {
            return;
        }
        // bound address seeds
        address msgSender = _indexToLpAddress(addressFromIndex);
        changePrank(msgSender);
        address addressTo = _seedToAddress(addressToSeed);

        // bound amount
        amount = bound(amount, 0, s_well.balanceOf(msgSender));

        // transfer
        s_well.transfer(addressTo, amount);

        // add the recipient to the set if not already there
        if (!s_LPs.contains(addressTo) && s_well.balanceOf(addressTo) > 0) {
            s_LPs.add(addressTo);
        }

        // remove the sender from the set if they have no more LP
        if (s_well.balanceOf(msgSender) == 0) {
            s_LPs.remove(msgSender);
        }
    }

    /// @dev approve
    function approveLP(uint addressFromIndex, uint addressToSeed, uint amount) public {
        if (s_LPs.length() == 0) {
            return;
        }
        // bound address seeds
        address msgSender = _indexToLpAddress(addressFromIndex);
        changePrank(msgSender);
        address addressTo = _seedToAddress(addressToSeed);

        // bound amount
        amount = bound(amount, 0, s_well.balanceOf(msgSender));

        // approve
        s_well.approve(addressTo, amount);

        // add to ghost variables
        s_approvedBy.add(msgSender);
        s_approvedTo[msgSender].add(addressTo);
    }

    /// @dev transferFrom
    function transferFromLP(uint addressApprovedByIndex, uint addressApprovedToIndex, uint amount) public {
        if (s_approvedBy.length() == 0) {
            return;
        }
        // bound address indices
        address approvedBy = _indexToApprovedByAddress(addressApprovedByIndex);
        address approvedTo = _indexToApprovedToAddress(approvedBy, addressApprovedToIndex);
        changePrank(approvedTo);

        // bound amount to between 0 and whichever is lower between the allowance and the balance of the approvedBy.
        uint allowance = s_well.allowance(approvedBy, approvedTo);
        uint balance = s_well.balanceOf(approvedBy);
        amount = bound(amount, 0, allowance <= balance ? allowance : balance);

        // transferFrom
        s_well.transferFrom(approvedBy, approvedTo, amount);

        // remove approvedBy from the s_LPs if the balance is 0
        if (s_well.balanceOf(approvedBy) == 0) {
            s_LPs.remove(approvedBy);
        }

        // add approvedTo to the s_LPs if the balance is greater than 0 and is not already there
        if (!s_LPs.contains(approvedTo) && s_well.balanceOf(approvedTo) > 0) {
            s_LPs.add(approvedTo);
        }
    }

    /// @dev Prints a call summary of calls and reverts to certain actions
    function callSummary() external view {
        console.log("swapTo Calls: %s", s_swapToCalls);
        console.log("swapTo Fails: %s", s_swapToFails);
        console.log("removeLiquidityOneToken Calls: %s", s_removeLiquidityOneTokenCalls);
        console.log("removeLiquidityOneToken Fails: %s", s_removeLiquidityOneTokenFails);
        console.log("removeLiquidityImbalanced Calls: %s", s_removeLiquidityImbalancedCalls);
        console.log("removeLiquidityImbalanced Fails: %s", s_removeLiquidityImbalancedFails);
        console.log("getShiftOut Calls: %s", s_getShiftOutCalls);
        console.log("getShiftOut Fails: %s", s_getShiftOutFails);
        console.log("shift Calls: %s", s_shiftCalls);
        console.log("shift Fails: %s", s_shiftFails);

        uint lpTotalSupply = s_well.totalSupply();
        IERC20[] memory mockTokens = s_well.tokens();
        uint wellToken0Balance = mockTokens[0].balanceOf(address(s_well));
        uint wellToken1Balance = mockTokens[1].balanceOf(address(s_well));
        console.log("LP Total Supply: %s", lpTotalSupply);
        console.log("Well token0 balance: %s", wellToken0Balance);
        console.log("Well token1 balance: %s", wellToken1Balance);
    }

    // helpers

    /// @dev Convert a seed to an address
    function _seedToAddress(uint addressSeed) internal view returns (address) {
        return address(uint160(bound(addressSeed, 1, type(uint160).max)));
    }

    /// @dev Convert an index to an existing LP address
    function _indexToLpAddress(uint addressIndex) internal view returns (address) {
        return s_LPs.at(bound(addressIndex, 0, s_LPs.length() - 1));
    }

    /// @dev Convert an index to an existing approvedBy address
    function _indexToApprovedByAddress(uint addressIndex) internal view returns (address) {
        return s_approvedBy.at(bound(addressIndex, 0, s_approvedBy.length() - 1));
    }

    /// @dev Convert an approvedBy address, and an index to an existing approvedTo address
    function _indexToApprovedToAddress(address approvedBy, uint addressIndex) internal view returns (address) {
        EnumerableSet.AddressSet storage approvedTo = s_approvedTo[approvedBy];
        return approvedTo.at(bound(addressIndex, 0, approvedTo.length() - 1));
    }
}
