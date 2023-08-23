// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IntegrationTestHelper, IERC20, console, Balances} from "test/integration/IntegrationTestHelper.sol";
import {IUniswapV2Router, IUniswapV3Router, IUniswapV2Factory} from "test/integration/interfaces/IUniswap.sol";
import {ConstantProduct2} from "test/TestHelper.sol";
import {IPipeline, PipeCall, AdvancedPipeCall, IDepot, From, To} from "test/integration/interfaces/IPipeline.sol";
import {LibMath} from "src/libraries/LibMath.sol";
import {Well} from "src/Well.sol";

/// @dev Tests gas usage of similar functions across Uniswap & Wells
contract IntegrationTestGasComparisons is IntegrationTestHelper {
    using LibMath for uint256;

    uint256 mainnetFork;

    Well daiWethWell;
    Well daiUsdcWell;
    ConstantProduct2 cp;
    bytes constant data = "";

    IUniswapV2Router uniV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory uniV2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV3Router constant uniV3Router = IUniswapV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IWETH constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    IPipeline pipeline = IPipeline(0xb1bE0000bFdcDDc92A8290202830C4Ef689dCeaa);
    IDepot depot = IDepot(0xDEb0f000082fD56C10f449d4f8497682494da84D);

    IERC20[] daiWethTokens = [DAI, IERC20(WETH)];
    IERC20[] daiUsdcTokens = [DAI, USDC];

    /// @dev pausing gas metrer
    function setUp() public {
        cp = new ConstantProduct2();

        mainnetFork = vm.createSelectFork("mainnet");
        assertEq(vm.activeFork(), mainnetFork);
        vm.rollFork(16_582_192);

        // Test contract has 5 * {TestHelper.initialLiquidity}
        daiWethWell = Well(setupWell(daiWethTokens, daiWethWell));
        daiUsdcWell = Well(setupWell(daiUsdcTokens, daiUsdcWell));
        _wellsInitializedHelper();
    }

    /// @dev Notes on fair comparison:
    ///
    /// 1. Gas will be dependent on input/output amount if the user's balance or the
    /// pool's balance move from zero to non-zero during execution. For example,
    /// if the user has no DAI and swaps from WETH->DAI, extra gas cost is incurred
    /// to set their DAI balance from 0 to non-zero.
    ///
    /// 2. Believe that some tokens don't decrement allowances if infinity is approved.
    /// Make sure that approval amounts are the same for each test.
    ///
    /// 3. The first few swaps in a new Well with a Pump attached will be more expensive,
    /// as the Pump will need to be initialized. Perform several swaps before testing
    /// to ensure we're at steady-state gas cost.

    //////////////////// COMPARE: WETH/DAI ////////////////////

    ////////// Wells

    function testFuzz_wells_WethDai_Swap(uint256 amountIn) public {
        vm.pauseGasMetering();
        amountIn = bound(amountIn, 1e18, daiWethTokens[1].balanceOf(address(this)));
        vm.resumeGasMetering();

        daiWethWell.swapFrom(daiWethTokens[1], daiWethTokens[0], amountIn, 0, address(this), type(uint256).max);
    }

    function testFuzz_wells_WethDaiUsdc_Swap(uint256 amountIn) public {
        vm.pauseGasMetering();
        amountIn = bound(amountIn, 1e18, 1000e18);

        WETH.approve(address(depot), type(uint256).max);

        // any user can approve pipeline for an arbritary set of assets.
        // this means that most users do not need to approve pipeline,
        // unless this is the first instance of the token being used.
        // the increased risk in max approving all assets within pipeline is small,
        // as any user can approve any contract to use the asset within pipeline.
        PipeCall[] memory _prePipeCall = new PipeCall[](2);

        // Approval transactions are done prior as pipeline is likley to have apporvals for popular
        // tokens done already, and this will save gas. However, if the user has not approved pipeline
        // they can check this off-chain, and decide to do the approval themselves.

        // Approve DAI:WETH Well to use pipeline's WETH
        _prePipeCall[0].target = address(WETH);
        _prePipeCall[0].data = abi.encodeWithSelector(WETH.approve.selector, address(daiWethWell), type(uint256).max);

        // Approve DAI:USDC Well to use pipeline's DAI
        _prePipeCall[1].target = address(DAI);
        _prePipeCall[1].data = abi.encodeWithSelector(DAI.approve.selector, address(daiUsdcWell), type(uint256).max);

        pipeline.multiPipe(_prePipeCall);

        AdvancedPipeCall[] memory _pipeCall = new AdvancedPipeCall[](2);

        // Swap WETH for DAI
        _pipeCall[0].target = address(daiWethWell);
        _pipeCall[0].callData = abi.encodeWithSelector(
            Well.swapFrom.selector, daiWethTokens[1], daiWethTokens[0], amountIn, 0, address(pipeline)
        );
        _pipeCall[0].clipboard = abi.encodePacked(uint256(0));

        // Swap DAI for USDC
        _pipeCall[1].target = address(daiUsdcWell);
        _pipeCall[1].callData =
            abi.encodeWithSelector(Well.swapFrom.selector, daiUsdcTokens[0], daiUsdcTokens[1], 0, 0, address(this));
        _pipeCall[1].clipboard = clipboardHelper(false, 0, ClipboardType.singlePaste, 1, 0, 2);

        bytes[] memory _farmCalls = new bytes[](2);
        _farmCalls[0] = abi.encodeWithSelector(
            depot.transferToken.selector, WETH, address(pipeline), amountIn, From.EXTERNAL, To.EXTERNAL
        );
        _farmCalls[1] = abi.encodeWithSelector(depot.advancedPipe.selector, _pipeCall, 0);

        vm.resumeGasMetering();
        depot.farm(_farmCalls);
    }

    function testFuzz_wells_WethDaiUsdc_Shift(uint256 amountIn) public {
        vm.pauseGasMetering();
        amountIn = bound(amountIn, 1e18, 1000e18);

        WETH.approve(address(depot), type(uint256).max);

        // unlike swap test (previous test), no tokens are sent back to pipeline.
        // this means that pipeline does not prior approvals.

        AdvancedPipeCall[] memory _pipeCall = new AdvancedPipeCall[](2);

        // Shift excess tokens into DAI; deliver to the DAI:USDC Well
        _pipeCall[0].target = address(daiWethWell);
        _pipeCall[0].callData = abi.encodeWithSelector(Well.shift.selector, DAI, 0, address(daiUsdcWell));
        _pipeCall[0].clipboard = abi.encodePacked(uint256(0));

        // Shift excess tokens into USDC; deliver to the user
        _pipeCall[1].target = address(daiUsdcWell);
        _pipeCall[1].callData = abi.encodeWithSelector(Well.shift.selector, daiUsdcTokens[1], 0, address(this));
        _pipeCall[1].clipboard = abi.encodePacked(uint256(0));

        // Send WETH directly to the DAI:WETH Well, then perform the Pipe calls above.
        bytes[] memory _farmCalls = new bytes[](2);
        _farmCalls[0] = abi.encodeWithSelector(
            depot.transferToken.selector, WETH, address(daiWethWell), amountIn, From.EXTERNAL, To.EXTERNAL
        );
        _farmCalls[1] = abi.encodeWithSelector(depot.advancedPipe.selector, _pipeCall, 0);

        vm.resumeGasMetering();
        depot.farm(_farmCalls);
    }

    function testFuzz_wells_WethDai_AddLiquidity(uint256 amount) public {
        vm.pauseGasMetering();
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = bound(amount, 1e18, 1000e18);
        amounts[1] = bound(amount, 1e18, 1000e18);
        vm.resumeGasMetering();

        daiWethWell.addLiquidity(amounts, 0, address(this), type(uint256).max);
    }

    function testFuzz_wells_WethDai_RemoveLiquidity(uint256 amount) public {
        vm.pauseGasMetering();
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = bound(amount, 1e18, 1000e18);
        amounts[1] = amounts[0];

        uint256[] memory reserves = new uint256[](2);
        reserves[0] = daiWethTokens[0].balanceOf(address(daiWethWell)) - amounts[0];
        reserves[1] = daiWethTokens[1].balanceOf(address(daiWethWell)) - amounts[1];

        uint256 EXP_PRECISION = 1e12;
        uint256 newLpTokenSupply = (reserves[0] * reserves[1] * EXP_PRECISION).sqrt();
        uint256 lpAmountBurned = daiWethWell.totalSupply() - newLpTokenSupply;
        uint256[] memory minAmountsOut = new uint256[](2);
        vm.resumeGasMetering();

        daiWethWell.removeLiquidity(lpAmountBurned, minAmountsOut, address(this), type(uint256).max);
    }

    ////////// Uniswap V2

    function testFuzz_uniswapV2_WethDai_Swap(uint256 amount) public {
        vm.pauseGasMetering();
        vm.assume(amount > 0);
        amount = bound(amount, 1e18, 1000 * 1e18);
        _uniSetupHelper(amount, address(uniV2Router));

        address[] memory path;
        path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(DAI);
        vm.resumeGasMetering();

        uniV2Router.swapExactTokensForTokens(amount, 0, path, msg.sender, block.timestamp);
    }

    function testFuzz_uniswapV2_WethDaiUsdc_Swap(uint256 amount) public {
        vm.pauseGasMetering();
        vm.assume(amount > 0);
        amount = bound(amount, 1e18, 1000 * 1e18);
        _uniSetupHelper(amount, address(uniV2Router));

        address[] memory path;
        path = new address[](3);
        path[0] = address(WETH);
        path[1] = address(DAI);
        path[2] = address(USDC);

        vm.resumeGasMetering();
        uniV2Router.swapExactTokensForTokens(amount, 0, path, msg.sender, block.timestamp);
    }

    function testFuzz_uniswapV2_WethDai_AddLiquidity(uint256 amount) public {
        vm.pauseGasMetering();
        amount = bound(amount, 1e18, 1000 * 1e18);
        _uniSetupHelper(amount, address(uniV2Router));
        vm.resumeGasMetering();

        uniV2Router.addLiquidity(address(WETH), address(DAI), amount, amount, 1, 1, address(this), block.timestamp);
    }

    function testFuzz_uniswapV2_WethDai_RemoveLiquidity(uint256 amount) public {
        vm.pauseGasMetering();
        amount = bound(amount, 1e18, 1000 * 1e18);
        _uniSetupHelper(amount, address(uniV2Router));

        uniV2Router.addLiquidity(address(WETH), address(DAI), amount, amount, 1, 1, address(this), block.timestamp);
        address pair = uniV2Factory.getPair(address(WETH), address(DAI));
        uint256 liquidity = IERC20(pair).balanceOf(address(this));
        IERC20(pair).approve(address(uniV2Router), type(uint256).max);

        vm.resumeGasMetering();

        uniV2Router.removeLiquidity(address(WETH), address(DAI), liquidity, 1, 1, address(this), block.timestamp);
    }

    ////////// Uniswap V3

    function testFuzz_uniswapV3_WethDai_Swap(uint256 amount) public {
        vm.pauseGasMetering();
        amount = bound(amount, 1e18, 1000 * 1e18);
        _uniSetupHelper(amount, address(uniV3Router));

        IUniswapV3Router.ExactInputSingleParams memory params = IUniswapV3Router.ExactInputSingleParams({
            tokenIn: address(WETH),
            tokenOut: address(DAI),
            fee: 3000,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        vm.resumeGasMetering();
        uniV3Router.exactInputSingle(params);
    }

    function testFuzz_uniswapV3_WethDaiUsdc_Swap(uint256 amount) public {
        vm.pauseGasMetering();
        amount = bound(amount, 1e18, 1000 * 1e18);
        _uniSetupHelper(amount, address(uniV3Router));

        IUniswapV3Router.ExactInputParams memory params = IUniswapV3Router.ExactInputParams({
            path: abi.encodePacked(address(WETH), uint24(3000), address(DAI), uint24(3000), address(USDC)),
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: 0
        });

        vm.resumeGasMetering();
        uniV3Router.exactInput(params);
    }

    //////////////////// SETUP HELPERS ////////////////////

    /// @dev Approve the `router` to swap Test contract's tokens.
    function _uniSetupHelper(uint256 amount, address router) private {
        deal(address(WETH), address(this), amount * 2);
        deal(address(DAI), address(this), amount * 2);
        WETH.approve(router, type(uint256).max);
        DAI.approve(router, type(uint256).max);
    }

    /// @dev Perform a few swaps on the provided Well to proper initialization.
    function _wellsInitializedHelper() private {
        // DAI -> WETH
        daiWethWell.swapFrom(
            daiWethTokens[0], daiWethTokens[1], 1000 * 1e18, 500 * 1e18, address(this), type(uint256).max
        );

        // WETH -> DAI
        vm.warp(block.timestamp + 1);
        daiWethWell.swapFrom(
            daiWethTokens[1], daiWethTokens[0], 500 * 1e18, 500 * 1e18, address(this), type(uint256).max
        );
    }
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}
