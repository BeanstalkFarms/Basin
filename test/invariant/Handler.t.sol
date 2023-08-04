// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {TestHelper, IERC20, Call, Balances} from "test/TestHelper.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {Snapshot, AddLiquidityAction, RemoveLiquidityAction, LiquidityHelper} from "test/LiquidityHelper.sol";
import {MockToken} from "mocks/tokens/MockToken.sol";
import {Well} from "src/Well.sol";
import {Invariants} from "./Invariants.t.sol";
import "forge-std/Test.sol";
import {EnumerableSet} from "oz/utils/structs/EnumerableSet.sol";

/// @dev The handler is the set of valid actions that can be performed during an invariant test run.
/// @dev These include adding and removing liquidity, transfers, swaps, shifts, etc.
contract Handler is Test {
    uint256 constant EXP_PRECISION = 1e12;

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
    uint256 internal s_swapToCalls;
    /// @dev The number of reverts on calling `swapTo`
    uint256 internal s_swapToFails;

    /// @dev The number of calls to `removeLiquidityOneToken`
    uint256 internal s_removeLiquidityOneTokenCalls;
    /// @dev The number of reverts on calling `removeLiquidityOneToken`
    uint256 internal s_removeLiquidityOneTokenFails;

    /// @dev The number of calls to `removeLiquidityImbalanced`
    uint256 internal s_removeLiquidityImbalancedCalls;
    /// @dev The number of reverts on calling `removeLiquidityImbalanced`
    uint256 internal s_removeLiquidityImbalancedFails;

    /// @dev The number of calls to `getShiftOut`
    uint256 internal s_getShiftOutCalls;
    /// @dev The number of reverts on calling `getShiftOut`
    uint256 internal s_getShiftOutFails;
    /// @dev The number of calls to `shift`
    uint256 internal s_shiftCalls;
    /// @dev The number of reverts on callling `shift`
    uint256 internal s_shiftFails;

    constructor(Well well) {
        s_LPs.add(msg.sender); // TestHelper adds initial liquidity
        s_well = well;
    }

    // IWELL
    // =====

    /// @dev swapFrom
    function swapFrom(uint256 addressSeed, uint256 tokenInIndex, uint256 amountIn) public {
        console.log("----------------------------------");
        console.log("Swap From");
        // bound address seed
        address msgSender = _seedToAddress(addressSeed);
        vm.startPrank(msgSender);
        // bound token index
        tokenInIndex = bound(tokenInIndex, 0, 1);
        uint256 tokenOutIndex = tokenInIndex == 0 ? 1 : 0;
        // bound amount in
        amountIn = bound(amountIn, 1, type(uint96).max);

        // mint tokens to the sender
        IERC20[] memory mockTokens = s_well.tokens();
        MockToken(address(mockTokens[tokenInIndex])).mint(msgSender, amountIn);
        // approve the well
        mockTokens[tokenInIndex].approve(address(s_well), amountIn);

        // swap
        uint256 minAmountOut = s_well.getSwapOut(mockTokens[tokenInIndex], mockTokens[tokenOutIndex], amountIn);
        s_well.swapFrom(
            mockTokens[tokenInIndex], mockTokens[tokenOutIndex], amountIn, minAmountOut, msgSender, block.timestamp
        );
        vm.stopPrank();
        printWellTokenValues();
    }

    /// @dev swapFromFeeOnTransfer - This won't actually take a fee on transfer, because in the current
    /// setup, we use non-fee taking tokens.
    function swapFromFeeOnTransfer(uint256 addressSeed, uint256 tokenInIndex, uint256 amountIn) public {
        console.log("----------------------------------");
        console.log("Swap From Fee On Transfer");
        // bound address seed
        address msgSender = _seedToAddress(addressSeed);
        vm.startPrank(msgSender);
        // bound token index
        tokenInIndex = bound(tokenInIndex, 0, 1);
        uint256 tokenOutIndex = tokenInIndex == 0 ? 1 : 0;
        // bound amount in
        amountIn = bound(amountIn, 1, type(uint96).max);

        // mint tokens to the sender
        IERC20[] memory mockTokens = s_well.tokens();
        MockToken(address(mockTokens[tokenInIndex])).mint(msgSender, amountIn);
        // approve the well
        mockTokens[tokenInIndex].approve(address(s_well), amountIn);

        // swap
        uint256 minAmountOut = s_well.getSwapOut(mockTokens[tokenInIndex], mockTokens[tokenOutIndex], amountIn);
        s_well.swapFromFeeOnTransfer(
            mockTokens[tokenInIndex], mockTokens[tokenOutIndex], amountIn, minAmountOut, msgSender, block.timestamp
        );
        vm.stopPrank();
        printWellTokenValues();
    }

    /// @dev swapTo
    function swapTo(uint256 addressSeed, uint256 tokenOutIndex, uint256 amountOut) public {
        console.log("----------------------------------");
        console.log("Swap To");
        s_swapToCalls++;
        // bound address seed
        address msgSender = _seedToAddress(addressSeed);
        vm.startPrank(msgSender);
        // bound token index
        tokenOutIndex = bound(tokenOutIndex, 0, 1);
        uint256 tokenInIndex = tokenOutIndex == 0 ? 1 : 0;
        // bound amount out
        amountOut = bound(amountOut, 1, type(uint96).max);

        // mint tokens to the sender
        IERC20[] memory mockTokens = s_well.tokens();
        // get amount in
        try s_well.getSwapIn(mockTokens[tokenInIndex], mockTokens[tokenOutIndex], amountOut) returns (uint256 amountIn)
        {
            if (amountIn > type(uint128).max) return;
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
        vm.stopPrank();
        printWellTokenValues();
    }

    /// @dev shift
    function shift(uint256 addressSeed) public {
        console.log("----------------------------------");
        console.log("Shift");
        // bound address seed
        address msgSender = _seedToAddress(addressSeed);
        vm.startPrank(msgSender);
        IERC20[] memory mockTokens = s_well.tokens();
        for (uint256 i; i < mockTokens.length; i++) {
            s_getShiftOutCalls++;
            try s_well.getShiftOut(mockTokens[i]) returns (uint256 amountOut) {
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
        vm.stopPrank();
        printWellTokenValues();
    }

    /// @dev addLiquidity
    function addLiquidity(uint256 addressSeed, uint256 token0AmountIn, uint256 token1AmountIn) public {
        console.log("----------------------------------");
        console.log("Add Liquidity");
        // bound address seed
        address msgSender = _seedToAddress(addressSeed);
        vm.startPrank(msgSender);
        // bound token amounts

        uint256[] memory reserves = s_well.getReserves();
        token0AmountIn = bound(token0AmountIn, 1, getMaxAddLiquidity(reserves));
        reserves[0] += token0AmountIn;
        token1AmountIn = bound(token1AmountIn, 1, getMaxAddLiquidity(reserves));

        uint256[] memory tokenAmountsIn = new uint256[](2);
        tokenAmountsIn[0] = token0AmountIn;
        tokenAmountsIn[1] = token1AmountIn;
        // mint tokens to the sender
        IERC20[] memory mockTokens = s_well.tokens();
        for (uint256 i; i < mockTokens.length; i++) {
            MockToken(address(mockTokens[i])).mint(msgSender, tokenAmountsIn[i]);
            // approve the well
            mockTokens[i].approve(address(s_well), tokenAmountsIn[i]);
        }

        // add liquidity
        uint256 minLpAmountOut = s_well.getAddLiquidityOut(tokenAmountsIn);
        uint256 lpAmountOut = s_well.addLiquidity(tokenAmountsIn, minLpAmountOut, msgSender, block.timestamp);
        assertGe(lpAmountOut, minLpAmountOut);
        // add the LP to the set
        s_LPs.add(msgSender);
        vm.stopPrank();
        printWellTokenValues();
    }

    /// @dev addLiquidityFeeOnTransfer - This won't actually take a fee on transfer, because in the current
    /// setup, we use non-fee taking tokens.
    function addLiquidityFeeOnTransfer(uint256 addressSeed, uint256 token0AmountIn, uint256 token1AmountIn) public {
        console.log("----------------------------------");
        console.log("Add Liquidity Fee on Transfer");
        // bound address seed
        address msgSender = _seedToAddress(addressSeed);
        vm.startPrank(msgSender);
        // bound token amounts
        uint256[] memory reserves = s_well.getReserves();
        token0AmountIn = bound(token0AmountIn, 1, getMaxAddLiquidity(reserves));
        reserves[0] += token0AmountIn;
        token1AmountIn = bound(token1AmountIn, 1, getMaxAddLiquidity(reserves));

        uint256[] memory tokenAmountsIn = new uint256[](2);
        tokenAmountsIn[0] = token0AmountIn;
        tokenAmountsIn[1] = token1AmountIn;
        // mint tokens to the sender
        IERC20[] memory mockTokens = s_well.tokens();
        for (uint256 i; i < mockTokens.length; i++) {
            MockToken(address(mockTokens[i])).mint(msgSender, tokenAmountsIn[i]);
            // approve the well
            mockTokens[i].approve(address(s_well), tokenAmountsIn[i]);
        }

        // add liquidity
        uint256 minLpAmountOut = s_well.getAddLiquidityOut(tokenAmountsIn);
        uint256 lpAmountOut =
            s_well.addLiquidityFeeOnTransfer(tokenAmountsIn, minLpAmountOut, msgSender, block.timestamp);
        assertGe(lpAmountOut, minLpAmountOut);

        // add the LP to the set
        s_LPs.add(msgSender);
        vm.stopPrank();
        printWellTokenValues();
    }

    /// @dev removeLiquidity
    function removeLiquidity(uint256 addressIndex, uint256 lpAmountIn) public {
        console.log("----------------------------------");
        console.log("Remove Liquidity");
        if (s_LPs.length() == 0) {
            return;
        }
        // bound address index
        address msgSender = _indexToLpAddress(addressIndex);
        vm.startPrank(msgSender);
        // bound lp amount
        lpAmountIn = bound(lpAmountIn, 0, s_well.balanceOf(msgSender));

        // remove liquidity
        uint256[] memory minTokenAmountsOut = s_well.getRemoveLiquidityOut(lpAmountIn);
        uint256[] memory tokenAmountsOut =
            s_well.removeLiquidity(lpAmountIn, minTokenAmountsOut, msgSender, block.timestamp);

        assertGe(tokenAmountsOut[0], minTokenAmountsOut[0]);
        assertGe(tokenAmountsOut[1], minTokenAmountsOut[1]);

        // remove the LP from the set if they have no more LP
        if (s_well.balanceOf(msgSender) == 0) {
            s_LPs.remove(msgSender);
        }
        vm.stopPrank();
        printWellTokenValues();
    }

    /// @dev removeLiquidityOneToken
    function removeLiquidityOneToken(uint256 addressIndex, uint256 tokenIndex, uint256 lpAmountIn) public {
        console.log("----------------------------------");
        console.log("remove Liquidity One Token");
        if (s_LPs.length() == 0) {
            return;
        }
        s_removeLiquidityOneTokenCalls++;
        // bound address index
        address msgSender = _indexToLpAddress(addressIndex);
        vm.startPrank(msgSender);
        // bound token index
        tokenIndex = bound(tokenIndex, 0, 1);
        IERC20 token = s_well.tokens()[tokenIndex];
        // bound lp amount
        lpAmountIn = bound(lpAmountIn, 0, s_well.balanceOf(msgSender));

        // remove liquidity
        try s_well.getRemoveLiquidityOneTokenOut(lpAmountIn, token) returns (uint256 minTokenAmountOut) {
            s_well.removeLiquidityOneToken(lpAmountIn, token, minTokenAmountOut, msgSender, block.timestamp);
            // remove the LP from the set if they have no more LP
            if (s_well.balanceOf(msgSender) == 0) {
                s_LPs.remove(msgSender);
            }
        } catch {
            s_removeLiquidityOneTokenFails++;
        }
        vm.stopPrank();
        printWellTokenValues();
    }

    /// @dev removeLiquidityImbalanced
    function removeLiquidityImbalanced(uint256 addressIndex, uint256 token0AmountOut, uint256 token1AmountOut) public {
        console.log("----------------------------------");
        console.log("Remove Liquidity Imbalanced");
        if (s_LPs.length() == 0) {
            return;
        }
        s_removeLiquidityImbalancedCalls++;
        // bound address index
        address msgSender = _indexToLpAddress(addressIndex);
        vm.startPrank(msgSender);
        // bound token amounts
        token0AmountOut = bound(token0AmountOut, 0, type(uint96).max);
        token1AmountOut = bound(token1AmountOut, 0, type(uint96).max);

        uint256[] memory tokenAmountsOut = new uint256[](2);
        tokenAmountsOut[0] = token0AmountOut;
        tokenAmountsOut[1] = token1AmountOut;

        // remove liquidity
        try s_well.getRemoveLiquidityImbalancedIn(tokenAmountsOut) returns (uint256 lpAmountIn) {
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
        vm.stopPrank();
        printWellTokenValues();
    }

    /// @dev sync
    function sync() public {
        console.log("----------------------------------");
        console.log("Sync");
        s_well.sync(address(this), 0);
        printWellTokenValues();
    }

    /// @dev skim
    function skim() public {
        console.log("----------------------------------");
        console.log("Skim");
        s_well.skim(address(this));
        printWellTokenValues();
    }

    // IERC20
    // ======

    /// @dev transfer
    function transferLP(uint256 addressFromIndex, uint256 addressToSeed, uint256 amount) public {
        console.log("----------------------------------");
        console.log("Transfer LP");
        if (s_LPs.length() == 0) {
            return;
        }
        // bound address seeds
        address msgSender = _indexToLpAddress(addressFromIndex);
        vm.startPrank(msgSender);
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
        vm.stopPrank();
        printWellTokenValues();
    }

    /// @dev approve
    function approveLP(uint256 addressFromIndex, uint256 addressToSeed, uint256 amount) public {
        console.log("----------------------------------");
        console.log("Approve LP");
        if (s_LPs.length() == 0) {
            return;
        }
        // bound address seeds
        address msgSender = _indexToLpAddress(addressFromIndex);
        vm.startPrank(msgSender);
        address addressTo = _seedToAddress(addressToSeed);

        // bound amount
        amount = bound(amount, 0, s_well.balanceOf(msgSender));

        // approve
        s_well.approve(addressTo, amount);

        // add to ghost variables
        s_approvedBy.add(msgSender);
        s_approvedTo[msgSender].add(addressTo);
        vm.stopPrank();
        printWellTokenValues();
    }

    /// @dev transferFrom
    function transferFromLP(uint256 addressApprovedByIndex, uint256 addressApprovedToIndex, uint256 amount) public {
        console.log("----------------------------------");
        console.log("Transfer From LP");
        if (s_approvedBy.length() == 0) {
            return;
        }
        // bound address indices
        address approvedBy = _indexToApprovedByAddress(addressApprovedByIndex);
        address approvedTo = _indexToApprovedToAddress(approvedBy, addressApprovedToIndex);
        vm.startPrank(approvedTo);

        // bound amount to between 0 and whichever is lower between the allowance and the balance of the approvedBy.
        uint256 allowance = s_well.allowance(approvedBy, approvedTo);
        uint256 balance = s_well.balanceOf(approvedBy);
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
        vm.stopPrank();
        printWellTokenValues();
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

        uint256 lpTotalSupply = s_well.totalSupply();
        IERC20[] memory mockTokens = s_well.tokens();
        uint256 wellToken0Balance = mockTokens[0].balanceOf(address(s_well));
        uint256 wellToken1Balance = mockTokens[1].balanceOf(address(s_well));
        console.log("LP Total Supply: %s", lpTotalSupply);
        console.log("Well token0 balance: %s", wellToken0Balance);
        console.log("Well token1 balance: %s", wellToken1Balance);
    }

    // helpers

    /// @dev Convert a seed to an address
    function _seedToAddress(uint256 addressSeed) internal view returns (address seedAddress) {
        uint160 boundInt = uint160(bound(addressSeed, 1, type(uint160).max));
        seedAddress = address(boundInt);
        if (seedAddress == address(s_well)) {
            uint160 newAddressSeed;
            unchecked {
                newAddressSeed = boundInt + 1;
            }
            seedAddress = _seedToAddress(uint256(newAddressSeed));
        }
    }

    /// @dev Convert an index to an existing LP address
    function _indexToLpAddress(uint256 addressIndex) internal view returns (address) {
        return s_LPs.at(bound(addressIndex, 0, s_LPs.length() - 1));
    }

    /// @dev Convert an index to an existing approvedBy address
    function _indexToApprovedByAddress(uint256 addressIndex) internal view returns (address) {
        return s_approvedBy.at(bound(addressIndex, 0, s_approvedBy.length() - 1));
    }

    /// @dev Convert an approvedBy address, and an index to an existing approvedTo address
    function _indexToApprovedToAddress(address approvedBy, uint256 addressIndex) internal view returns (address) {
        EnumerableSet.AddressSet storage approvedTo = s_approvedTo[approvedBy];
        return approvedTo.at(bound(addressIndex, 0, approvedTo.length() - 1));
    }

    function printWellTokenValues() internal view {
        uint256 functionCalc = IWellFunction(s_well.wellFunction().target).calcLpTokenSupply(
            s_well.getReserves(), s_well.wellFunction().data
        );
        console.log("Token Supply: %s", s_well.totalSupply());
        console.log("Expec Supply: %s", functionCalc);

        IERC20[] memory mockTokens = s_well.tokens();
        console.log("Well token0 balance: %s", mockTokens[0].balanceOf(address(s_well)));
        console.log("Well token1 balance: %s", mockTokens[1].balanceOf(address(s_well)));

        uint256[] memory reserves = s_well.getReserves();
        console.log("Reserve0: %s", reserves[0]);
        console.log("Reserve1: %s", reserves[1]);
    }

    function getMaxAddLiquidity(uint256[] memory reserves) internal pure returns (uint256 max) {
        if (reserves[0] == 0 || reserves[1] == 0) return type(uint96).max;
        max = type(uint256).max / (reserves[0] * reserves[1] * EXP_PRECISION);
        if (max > type(uint96).max) max = type(uint96).max;
    }
}
