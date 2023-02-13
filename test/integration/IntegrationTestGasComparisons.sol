// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IntegrationTestHelper, IERC20, console, Balances} from "test/integration/IntegrationTestHelper.sol";
import {IUniswapV2Router, IUniswapV3Router, IUniswapV2Factory} from "test/integration/interfaces/IUniswap.sol";
import {ConstantProduct2} from "test/TestHelper.sol";

import {Well} from "src/Well.sol";

/// @dev Tests gas usage of similar functions across Uniswap & Wells
contract IntegrationTestGasComparisons is IntegrationTestHelper {
    uint mainnetFork;

    Well daiWethWell;
    ConstantProduct2 cp;
    bytes constant data = "";

    IUniswapV2Router uniV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory uniV2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV3Router constant uniV3Router = IUniswapV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IWETH constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    IERC20[] _tokens = [DAI, IERC20(WETH)];

    /// @dev pausing gas metrer
    function setUp() public {
        cp = new ConstantProduct2();

        mainnetFork = vm.createSelectFork("mainnet");
        assertEq(vm.activeFork(), mainnetFork);
        vm.rollFork(16_582_192);

        // Test contract has 5 * {TestHelper.initialLiquidity}
        setupWell(_tokens, daiWethWell);
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

    function testFuzz_wells_WethDai_Swap(uint amountIn) public {
        vm.pauseGasMetering();
        uint amountIn = bound(amountIn, 1e18, _tokens[1].balanceOf(address(this)));
        vm.resumeGasMetering();

        well.swapFrom(_tokens[1], _tokens[0], amountIn, 0, address(this));
    }

    function testFuzz_wells_WethDaiUsdc_Swap(uint amountIn) public {}

    function testFuzz_wells_WethDai_AddLiquidity(uint amount) public {
        vm.pauseGasMetering();
        uint[] memory amounts = new uint[](2);
        amounts[0] = bound(amount, 1e18, 1000e18);
        amounts[1] = bound(amount, 1e18, 1000e18);
        vm.resumeGasMetering();

        well.addLiquidity(amounts, 0, address(this));
    }

    function testFuzz_wells_WethDai_RemoveLiquidity(uint amount) public {
        vm.pauseGasMetering();
        uint[] memory amounts = new uint[](2);
        amounts[0] = bound(amount, 1e18, 1000e18);
        amounts[1] = amounts[0];

        uint[] memory reserves = new uint[](2);
        reserves[0] = _tokens[0].balanceOf(address(well)) - amounts[0];
        reserves[1] = _tokens[1].balanceOf(address(well)) - amounts[1];

        uint newLpTokenSupply = cp.calcLpTokenSupply(reserves, data);
        uint lpAmountBurned = well.totalSupply() - newLpTokenSupply;
        uint[] memory minAmountsOut = new uint[](2);
        vm.resumeGasMetering();

        well.removeLiquidity(lpAmountBurned, minAmountsOut, address(this));
    }

    ////////// Uniswap V2

    function testFuzz_uniswapV2_WethDai_Swap(uint amount) public {
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

    function testFuzz_uniswapV2_WethDaiUsdc_Swap(uint amount) public {
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

    function testFuzz_uniswapV2_WethDai_AddLiquidity(uint amount) public {
        vm.pauseGasMetering();
        amount = bound(amount, 1e18, 1000 * 1e18);
        _uniSetupHelper(amount, address(uniV2Router));
        vm.resumeGasMetering();

        uniV2Router.addLiquidity(address(WETH), address(DAI), amount, amount, 1, 1, address(this), block.timestamp);
    }

    function testFuzz_uniswapV2_WethDai_RemoveLiquidity(uint amount) public {
        vm.pauseGasMetering();
        amount = bound(amount, 1e18, 1000 * 1e18);
        _uniSetupHelper(amount, address(uniV2Router));

        uniV2Router.addLiquidity(address(WETH), address(DAI), amount, amount, 1, 1, address(this), block.timestamp);
        address pair = uniV2Factory.getPair(address(WETH), address(DAI));
        uint liquidity = IERC20(pair).balanceOf(address(this));
        IERC20(pair).approve(address(uniV2Router), type(uint).max);

        vm.resumeGasMetering();

        uniV2Router.removeLiquidity(address(WETH), address(DAI), liquidity, 1, 1, address(this), block.timestamp);
    }

    ////////// Uniswap V3

    function testFuzz_uniswapV3_WethDai_Swap(uint amount) public {
        vm.pauseGasMetering();
        amount = bound(amount, 1e18, 1000 * 1e18);
        _uniSetupHelper(amount, address(uniV3Router));
        vm.resumeGasMetering();

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

        uniV3Router.exactInputSingle(params);
    }

    function testFuzz_uniswapV3_WethDaiUsdc_Swap(uint amount) public {
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
    function _uniSetupHelper(uint amount, address router) private {
        deal(address(WETH), address(this), amount * 2);
        deal(address(DAI), address(this), amount * 2);
        WETH.approve(router, type(uint).max);
        DAI.approve(router, type(uint).max);
    }

    /// @dev Perform a few swaps on the provided Well to proper initialization.
    function _wellsInitializedHelper() private {
        // DAI -> WETH
        well.swapFrom(_tokens[0], _tokens[1], 1000 * 1e18, 500 * 1e18, address(this));

        // WETH -> DAI
        vm.warp(block.number + 1);
        well.swapFrom(_tokens[1], _tokens[0], 500 * 1e18, 500 * 1e18, address(this));
    }
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint amount) external;
}
