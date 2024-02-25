// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {TestHelper, IERC20, Call, Balances} from "test/TestHelper.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {Snapshot, AddLiquidityAction, RemoveLiquidityAction, LiquidityHelper} from "test/LiquidityHelper.sol";
import {IPump, MultiFlowPump} from "src/pumps/MultiFlowPump.sol";
import {Handler} from "./Handler.t.sol";
import "../pumps/PumpHelpers.sol";
import "forge-std/Test.sol";
import {MockToken} from "mocks/tokens/MockToken.sol";

/// @dev This contract deploys the target contract, the Handler, adds the Handler's actions to the invariant fuzzing
/// @dev targets, then defines invariants that should always hold throughout any invariant run.
contract Invariants is LiquidityHelper {
    Handler internal s_handler;

    function setUp() public {
        // setup the pump
        IPump pump = new MultiFlowPump();
        Call[] memory pumps = new Call[](1);
        pumps[0] = Call({target: address(pump), data: new bytes(0)});

        // setup the well
        setupWell(2, deployWellFunction(), pumps);
        // create the handler
        s_handler = new Handler(well);

        // add the handler selectors to the fuzzing targets
        bytes4[] memory selectors = new bytes4[](14);
        // IERC20
        selectors[0] = Handler.transferLP.selector;
        // IWell
        selectors[1] = Handler.addLiquidity.selector;
        selectors[2] = Handler.removeLiquidity.selector;
        selectors[3] = Handler.removeLiquidityOneToken.selector;
        selectors[4] = Handler.removeLiquidityImbalanced.selector;
        selectors[5] = Handler.sync.selector;
        selectors[6] = Handler.skim.selector;
        selectors[7] = Handler.swapFrom.selector;
        selectors[8] = Handler.swapTo.selector;
        selectors[9] = Handler.addLiquidityFeeOnTransfer.selector;
        selectors[10] = Handler.swapFromFeeOnTransfer.selector;
        selectors[11] = Handler.shift.selector;
        selectors[12] = Handler.approveLP.selector;
        selectors[13] = Handler.transferFromLP.selector;

        targetSelector(FuzzSelector({addr: address(s_handler), selectors: selectors}));
        targetContract(address(s_handler));
    }

    /// @dev The total supply calculated by the well function should equal the totalSupply of the well
    function invariant_totalSupplyMatchesFunctionCalc() public {
        uint256[] memory reserves = well.getReserves();

        uint256 functionCalc = IWellFunction(wellFunction.target).calcLpTokenSupply(reserves, wellFunction.data);

        uint256 precision = getPrecisionForReserves(reserves);
        // Future TODO: fix for precision 0
        if (precision == 0) return;

        assertApproxEqRelN(well.totalSupply(), functionCalc, precision);
        assertLe(well.totalSupply(), functionCalc);
    }

    /// @dev The reserves calculated by the well function should equal the reserves of the well
    function invariant_reservesMatchFunctionCalcReserve() public {
        uint256[] memory reserves = well.getReserves();

        uint256 reserve0 =
            IWellFunction(wellFunction.target).calcReserve(reserves, 0, well.totalSupply(), wellFunction.data);
        uint256 reserve1 =
            IWellFunction(wellFunction.target).calcReserve(reserves, 1, well.totalSupply(), wellFunction.data);

        uint256 precision = getPrecisionForReserves(reserves);
        // Future TODO: fix for precision 0
        if (precision == 0) return;

        assertApproxEqRelN(reserves[0], reserve0, 2, precision);
        assertApproxEqRelN(reserves[1], reserve1, 2, precision);
    }

    /// @dev The token0 balance of the well should be greater than or equal to the reserve0
    function invariant_token0WellBalanceAndReserves() public {
        IERC20[] memory mockTokens = well.tokens();
        uint256[] memory reserves = well.getReserves();
        assertGe(mockTokens[0].balanceOf(address(well)), reserves[0]);
    }

    /// @dev The token1 balance of the well should be greater than or equal to the reserve1
    function invariant_token1WellBalanceAndReserves() public {
        IERC20[] memory mockTokens = well.tokens();
        uint256[] memory reserves = well.getReserves();
        assertGe(mockTokens[1].balanceOf(address(well)), reserves[1]);
    }

    /// @dev Token balances of the well should never be zero if there are LP tokens in supply
    function invariant_wellTokenBalancesShouldNeverBeZeroWithLPSupply() public {
        IERC20[] memory mockTokens = well.tokens();
        if (well.totalSupply() != 0) {
            assertGt(mockTokens[0].balanceOf(address(well)), 0);
            assertGt(mockTokens[1].balanceOf(address(well)), 0);
        }
    }

    /// @dev If LP token supply is 0, there should be no reserves in the well
    function invariant_lpSupplyShouldNeverBeZeroIfReservesAreInThePool() public {
        IERC20[] memory mockTokens = well.tokens();
        if (well.totalSupply() == 0) {
            // Check if either reserve is 0
            if (mockTokens[0].balanceOf(address(well)) > 0) {
                assertEq(mockTokens[1].balanceOf(address(well)), 0);
            }
        }
    }

    /// @dev helper function to return detailed information about the invariant runs
    function invariant_callSummary() public view {
        s_handler.callSummary();
    }
}
