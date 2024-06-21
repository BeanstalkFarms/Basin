// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockTokenFeeOnTransfer, TestHelper, IERC20, Balances, Call, MockToken, Well} from "test/TestHelper.sol";
import {SwapHelper, SwapAction, Snapshot} from "test/SwapHelper.sol";
import {MockFunctionBad} from "mocks/functions/MockFunctionBad.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {IWell} from "src/interfaces/IWell.sol";
import {IWellErrors} from "src/interfaces/IWellErrors.sol";

/**
 * @dev Tests {swapFromFeeOnTransfer} when tokens involved in the swap incur
 * a fee on transfer.
 */
contract WellSwapFromFeeOnTransferFeeTest is SwapHelper {
    function setUp() public {
        tokens = new IERC20[](2);
        tokens[0] = deployMockTokenFeeOnTransfer(0); // token[0] has fee
        tokens[1] = deployMockToken(1); // token[1] has no fee
        setupWell(deployWellFunction(), deployPumps(2), tokens);
        MockTokenFeeOnTransfer(address(tokens[0])).setFee(1e16);
    }

    /**
     * @dev swapFromFeeOnTransfer: slippage revert if minAmountOut is too high.
     * Since a fee is charged on `amountIn`, `amountOut` falls below the slippage
     * threshold.
     */
    function test_swapFromFeeOnTransferWithFee_revertIf_minAmountOutTooHigh() public prank(user) {
        uint256 amountIn = 1000 * 1e18;
        uint256 minAmountOut = 500 * 1e18;
        uint256 amountOut = well.getSwapOut(tokens[0], tokens[1], amountIn - _getFee(amountIn));

        vm.expectRevert(abi.encodeWithSelector(IWellErrors.SlippageOut.selector, amountOut, minAmountOut));
        well.swapFromFeeOnTransfer(tokens[0], tokens[1], amountIn, minAmountOut, user, type(uint256).max);
    }

    /**
     * @dev tokens[0]: 1% fee / tokens[1]: No fee
     *
     * Swapping from tokens[0] -> tokens[1]
     *
     * User spends:     amountIn            token0
     * Well receives:   amountIn - fee      token0
     * Well sends:      amountOut           token1
     * User receives:   amountOut           token1
     */
    function testFuzz_swapFromFeeOnTransferWithFee_fromToken(uint256 amountIn) public prank(user) {
        amountIn = bound(amountIn, 0, tokens[0].balanceOf(address(user)));
        Snapshot memory bef;
        SwapAction memory act;

        // Setup delta
        act.i = 0;
        act.j = 1;
        act.userSpends = amountIn;
        act.wellReceives = amountIn - _getFee(act.userSpends);
        act.wellSends = well.getSwapOut(tokens[act.i], tokens[act.j], act.wellReceives);
        act.userReceives = act.wellSends;

        (bef, act) = beforeSwapFrom(act);

        // Perform swap; returns the amount that the Well sent NOT including any transfer fee
        uint256 amountOut = well.swapFromFeeOnTransfer(
            tokens[act.i], tokens[act.j], amountIn, act.userReceives, user, type(uint256).max
        );

        assertEq(amountOut, act.wellSends, "amountOut different than calculated");
        afterSwapFrom(bef, act);
    }

    /**
     * @dev tokens[0]: 1% fee / tokens[1]: No fee
     *
     * Swapping from tokens[1] -> tokens[0]
     *
     * User spends:     amountIn            token0
     * Well receives:   amountIn            token0
     * Well sends:      amountOut           token1
     * User receives:   amountOut - fee     token1
     *
     * NOTE: Since the fee is incurred after `amountOut` is calculated in the Well,
     * the Swap event contains the amount sent by the Well, which will be larger
     * than the amount received by the User.
     */
    function testFuzz_swapFromFeeOnTransferWithFee_toToken(uint256 amountIn) public prank(user) {
        amountIn = bound(amountIn, 0, tokens[1].balanceOf(address(well)));
        Snapshot memory bef;
        SwapAction memory act;

        // Setup delta
        act.i = 1;
        act.j = 0;
        act.userSpends = amountIn;
        act.wellReceives = amountIn;
        act.wellSends = well.getSwapOut(tokens[act.i], tokens[act.j], amountIn);
        act.userReceives = act.wellSends - _getFee(act.wellSends);

        (bef, act) = beforeSwapFrom(act);

        // Perform swap; returns the amount that the Well sent NOT including any transfer fee
        uint256 amountOut = well.swapFromFeeOnTransfer(
            tokens[act.i], tokens[act.j], amountIn, act.userReceives, user, type(uint256).max
        );

        assertEq(amountOut, act.wellSends, "amountOut different than calculated");
        afterSwapFrom(bef, act);
    }

    function _getFee(uint256 amount) internal view returns (uint256) {
        return amount * MockTokenFeeOnTransfer(address(tokens[0])).fee() / 1e18;
    }
}
