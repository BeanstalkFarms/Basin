// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IntegrationTestHelper, IERC20, console, Balances} from "test/integration/IntegrationTestHelper.sol";
import {IUniswapV2Router, IUniswapV3Router, IUniswapV2Factory} from "test/integration/interfaces/IUniswap.sol";
import {ConstantProduct2} from "test/TestHelper.sol";

/// @dev Tests gas usage of similar functions across Uniswap & Wells
contract IntegrationTestGasComparisons is IntegrationTestHelper {
    uint mainnetFork;

    ConstantProduct2 cp;
    bytes constant data = "";

    IUniswapV2Router uniV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory uniV2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV3Router constant uniV3Router = IUniswapV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IWETH constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    IERC20[] _tokens = [DAI, IERC20(WETH)];

    function setUp() public {
        cp = new ConstantProduct2();

        mainnetFork = vm.createSelectFork("mainnet");
        assertEq(vm.activeFork(), mainnetFork);
        vm.rollFork(16_582_192);

        setupWell(_tokens);
        _wellsInitializedHelper(); // do some swaps to make sure oracles initialized
    }

    function testFuzz_wells_WethDai_Swap(uint amountOut) public {
        vm.pauseGasMetering();
        uint maxAmountIn = 1000 * 1e18;
        amountOut = bound(amountOut, 1e18, 500 * 1e18);
        vm.resumeGasMetering();

        well.swapFrom(_tokens[1], _tokens[0], maxAmountIn, amountOut, address(this));
    }

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

    /// @dev Approve the `router` to swap Test contract's tokens.
    function _uniSetupHelper(uint amount, address router) private {
        deal(address(WETH), address(this), amount * 2);
        deal(address(DAI), address(this), amount * 2);
        WETH.approve(router, type(uint).max);
        DAI.approve(router, type(uint).max);
    }

    /// @dev Perform a few swaps on the provided Well to proper initialization.
    function _wellsInitializedHelper() private {
        well.swapFrom(_tokens[0], _tokens[1], 1000 * 1e18, 500 * 1e18, address(this));
        vm.warp(block.number + 1);
        well.swapFrom(_tokens[1], _tokens[0], 500 * 1e18, 500 * 1e18, address(this));
        // vm.warp(block.number + 1);
        // well.swapFrom(_tokens[1], _tokens[0], 250 * 1e18, 250 * 1e18, address(this));
    }
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint amount) external;
}
