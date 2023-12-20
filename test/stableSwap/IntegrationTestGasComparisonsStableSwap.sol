// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IntegrationTestHelper, IERC20, console, Balances} from "test/integration/IntegrationTestHelper.sol";
import {ICurvePool, ICurveZap} from "test/integration/interfaces/ICurve.sol";
import {StableSwap2} from "test/TestHelper.sol";
import {IPipeline, PipeCall, AdvancedPipeCall, IDepot, From, To} from "test/integration/interfaces/IPipeline.sol";
import {LibMath} from "src/libraries/LibMath.sol";
import {Well} from "src/Well.sol";

/// @dev Tests gas usage of similar functions across Curve & Wells
contract IntegrationTestGasComparisonsStableSwap is IntegrationTestHelper {
    using LibMath for uint256;

    uint256 mainnetFork;

    Well daiBeanWell;
    Well daiUsdcWell;
    StableSwap2 ss;
    bytes data = "";

    ICurvePool bean3Crv = ICurvePool(0xc9C32cd16Bf7eFB85Ff14e0c8603cc90F6F2eE49);
    ICurveZap zap = ICurveZap(0xA79828DF1850E8a3A3064576f380D90aECDD3359);

    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant BEAN = IERC20(0xBEA0000029AD1c77D3d5D23Ba2D8893dB9d1Efab);
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant THREE3CRV = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);


    IPipeline pipeline = IPipeline(0xb1bE0000bFdcDDc92A8290202830C4Ef689dCeaa);
    IDepot depot = IDepot(0xDEb0f000082fD56C10f449d4f8497682494da84D);

    IERC20[] daiBeanTokens = [DAI, BEAN];
    IERC20[] daiUsdcTokens = [DAI, USDC];


    /// @dev pausing gas metrer
    function setUp() public {
        ss = new StableSwap2();

        mainnetFork = vm.createSelectFork("mainnet");
        assertEq(vm.activeFork(), mainnetFork);

        // Test contract has 5 * {TestHelper.initialLiquidity}, with an A parameter of 10.
        daiBeanWell = Well(setupStableSwapWell(10, daiBeanTokens, daiBeanWell));
        daiUsdcWell = Well(setupStableSwapWell(10, daiUsdcTokens, daiUsdcWell));

        _wellsInitializedHelper();
    }

    /// @dev Notes on fair comparison:
    ///
    /// 1. Gas will be dependent on input/output amount if the user's balance or the
    /// pool's balance move from zero to non-zero during execution. For example,
    /// if the user has no DAI and swaps from BEAN->DAI, extra gas cost is incurred
    /// to set their DAI balance from 0 to non-zero.
    ///
    /// 2. Believe that some tokens don't decrement allowances if infinity is approved.
    /// Make sure that approval amounts are the same for each test.
    ///
    /// 3. The first few swaps in a new Well with a Pump attached will be more expensive,
    /// as the Pump will need to be initialized. Perform several swaps before testing
    /// to ensure we're at steady-state gas cost.

    //////////////////// COMPARE: BEAN/DAI ////////////////////

    ////////// Wells

    function testFuzz_wells_BeanDai_Swap(uint256 amountIn) public {
        vm.pauseGasMetering();
        amountIn = bound(amountIn, 1e18, daiBeanTokens[1].balanceOf(address(this)));
        vm.resumeGasMetering();

        daiBeanWell.swapFrom(daiBeanTokens[1], daiBeanTokens[0], amountIn, 0, address(this), type(uint256).max);
    }

    function testFuzz_wells_BeanDaiUsdc_Swap(uint256 amountIn) public {
        vm.pauseGasMetering();
        amountIn = bound(amountIn, 1e18, 1000e18);

        BEAN.approve(address(depot), type(uint256).max);

        // any user can approve pipeline for an arbritary set of assets.
        // this means that most users do not need to approve pipeline,
        // unless this is the first instance of the token being used.
        // the increased risk in max approving all assets within pipeline is small,
        // as any user can approve any contract to use the asset within pipeline.
        PipeCall[] memory _prePipeCall = new PipeCall[](2);

        // Approval transactions are done prior as pipeline is likley to have apporvals for popular
        // tokens done already, and this will save gas. However, if the user has not approved pipeline
        // they can check this off-chain, and decide to do the approval themselves.

        // Approve DAI:BEAN Well to use pipeline's BEAN
        _prePipeCall[0].target = address(BEAN);
        _prePipeCall[0].data = abi.encodeWithSelector(BEAN.approve.selector, address(daiBeanWell), type(uint256).max);

        // Approve DAI:USDC Well to use pipeline's DAI
        _prePipeCall[1].target = address(DAI);
        _prePipeCall[1].data = abi.encodeWithSelector(DAI.approve.selector, address(daiUsdcWell), type(uint256).max);

        pipeline.multiPipe(_prePipeCall);

        AdvancedPipeCall[] memory _pipeCall = new AdvancedPipeCall[](2);

        // Swap BEAN for DAI
        _pipeCall[0].target = address(daiBeanWell);
        _pipeCall[0].callData = abi.encodeWithSelector(
            Well.swapFrom.selector, daiBeanTokens[1], daiBeanTokens[0], amountIn, 0, address(pipeline)
        );
        _pipeCall[0].clipboard = abi.encodePacked(uint256(0));

        // Swap DAI for USDC
        _pipeCall[1].target = address(daiUsdcWell);
        _pipeCall[1].callData =
            abi.encodeWithSelector(Well.swapFrom.selector, daiUsdcTokens[0], daiUsdcTokens[1], 0, 0, address(this));
        _pipeCall[1].clipboard = clipboardHelper(false, 0, ClipboardType.singlePaste, 1, 0, 2);

        bytes[] memory _farmCalls = new bytes[](2);
        _farmCalls[0] = abi.encodeWithSelector(
            depot.transferToken.selector, BEAN, address(pipeline), amountIn, From.EXTERNAL, To.EXTERNAL
        );
        _farmCalls[1] = abi.encodeWithSelector(depot.advancedPipe.selector, _pipeCall, 0);

        vm.resumeGasMetering();
        depot.farm(_farmCalls);
    }

    function testFuzz_wells_BeanDaiUsdc_Shift(uint256 amountIn) public {
        vm.pauseGasMetering();
        amountIn = bound(amountIn, 1e18, 1000e18);

        BEAN.approve(address(depot), type(uint256).max);

        // unlike swap test (previous test), no tokens are sent back to pipeline.
        // this means that pipeline does not prior approvals.

        AdvancedPipeCall[] memory _pipeCall = new AdvancedPipeCall[](2);

        // Shift excess tokens into DAI; deliver to the DAI:USDC Well
        _pipeCall[0].target = address(daiBeanWell);
        _pipeCall[0].callData = abi.encodeWithSelector(Well.shift.selector, DAI, 0, address(daiUsdcWell));
        _pipeCall[0].clipboard = abi.encodePacked(uint256(0));

        // Shift excess tokens into USDC; deliver to the user
        _pipeCall[1].target = address(daiUsdcWell);
        _pipeCall[1].callData = abi.encodeWithSelector(Well.shift.selector, daiUsdcTokens[1], 0, address(this));
        _pipeCall[1].clipboard = abi.encodePacked(uint256(0));

        // Send BEAN directly to the DAI:BEAN Well, then perform the Pipe calls above.
        bytes[] memory _farmCalls = new bytes[](2);
        _farmCalls[0] = abi.encodeWithSelector(
            depot.transferToken.selector, BEAN, address(daiBeanWell), amountIn, From.EXTERNAL, To.EXTERNAL
        );
        _farmCalls[1] = abi.encodeWithSelector(depot.advancedPipe.selector, _pipeCall, 0);

        vm.resumeGasMetering();
        depot.farm(_farmCalls);
    }

    function testFuzz_wells_BeanDai_AddLiquidity(uint256 amount) public {
        vm.pauseGasMetering();
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = bound(amount, 1e18, 1000e18);
        amounts[1] = bound(amount, 1e18, 1000e18);
        vm.resumeGasMetering();

        daiBeanWell.addLiquidity(amounts, 0, address(this), type(uint256).max);
    }

    function testFuzz_wells_BeanDai_RemoveLiquidity(uint256 amount) public {
        vm.pauseGasMetering();
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = bound(amount, 1e18, 1000e18);
        amounts[1] = amounts[0];
        uint256 lp = daiBeanWell.addLiquidity(amounts, 0, address(this), type(uint256).max);
        uint256[] memory minAmountsOut = new uint256[](2);
        vm.resumeGasMetering();

        daiBeanWell.removeLiquidity(lp, minAmountsOut, address(this), type(uint256).max);
    }

    ////////// Curve

    function testFuzz_curve_BeanDai_Swap(uint256 amount) public {
        vm.pauseGasMetering();
        vm.assume(amount > 0);
        amount = bound(amount, 1e18, 1000 * 1e18);
        _curveSetupHelper(amount);

        int128 i = 0; // from bean
        int128 j = 1; // to dai

        vm.resumeGasMetering();

        bean3Crv.exchange_underlying(i, j, amount, 0);
    }


    function testFuzz_curve_AddLiquidity(uint256 amount) public {
        vm.pauseGasMetering();
        uint256[2] memory amounts;
        amount = bound(amount, 1e18, 1000 * 1e18);
        amounts[0] = 0;
        amounts[1] = amount;

        _curveSetupHelper(amount);
        vm.resumeGasMetering();

        bean3Crv.add_liquidity(amounts, 0);
    }

    function testFuzz_curve_BeanDai_RemoveLiquidity(uint256 amount) public {
        vm.pauseGasMetering();
        uint256[2] memory amounts;
        amount = bound(amount, 1e18, 1000 * 1e18);
        amounts[0] = 0;
        amounts[1] = amount;

        _curveSetupHelper(amount);
        uint256 liquidity = bean3Crv.add_liquidity(amounts, 0);
        vm.resumeGasMetering();

        bean3Crv.remove_liquidity_one_coin(liquidity, 0, 0);
    }

    //////////////////// SETUP HELPERS ////////////////////

    /// @dev Approve the `router` to swap Test contract's tokens.
    function _curveSetupHelper(uint256 amount) private {
        deal(address(BEAN), address(this), amount * 2);
        deal(address(DAI), address(this), amount * 2);
        deal(address(THREE3CRV), address(this), amount * 2);

        BEAN.approve(address(bean3Crv), type(uint256).max);
        DAI.approve(address(bean3Crv), type(uint256).max);
        THREE3CRV.approve(address(bean3Crv), type(uint256).max);

        BEAN.approve(address(zap), type(uint256).max);
        DAI.approve(address(zap), type(uint256).max);
        THREE3CRV.approve(address(zap), type(uint256).max);
    }

    /// @dev Perform a few swaps on the provided Well to proper initialization.
    function _wellsInitializedHelper() private {
        // DAI -> BEAN
        daiBeanWell.swapFrom(
            daiBeanTokens[0], daiBeanTokens[1], 1000 * 1e18, 500 * 1e18, address(this), type(uint256).max
        );

        // BEAN -> DAI
        vm.warp(block.timestamp + 1);
        daiBeanWell.swapFrom(
            daiBeanTokens[1], daiBeanTokens[0], 500 * 1e18, 500 * 1e18, address(this), type(uint256).max
        );
    }
}

interface IBEAN is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}
