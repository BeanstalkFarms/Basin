/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "oz/token/ERC20/extensions/draft-ERC20Permit.sol";

import "src/interfaces/IWell.sol";
import "src/interfaces/IPump.sol";
import "src/interfaces/IWellFunction.sol";

import "src/utils/ImmutableTokens.sol";
import "src/utils/ImmutablePump.sol";
import "src/utils/ImmutableWellFunction.sol";

/**
 * @author Publius
 * @title Well
 * @dev
 * A Well serves as an constant function AMM allowing the provisioning of liquidity into a single pooled on-chain liquidity position.
 * Each Well has tokens, a pricing function, and a pump.
 * - Tokens defines the set of tokens that can be exchanged in the pool.
 * - The pricing function defines an invariant relationship between the balances of the tokens in the pool and the number of LP tokens. See {IWellFunction}
 * - Pumps are on-chain oracles that are updated every time the pool is interacted with. See {IPump}. Including a Pump is optional.
 *   Only 1 Pump can be attached to a Well, but a Pump can call other Pumps, allowing multiple Pumps to be used.
 * a Well's tokens, well function and pump are stored as immutable variables to prevent unnessary SLOAD calls.
 * 
 * Users can swap tokens in and add/remove liquidity to a Well.
 *
 * Implementation of ERC-20, ERC-2612 and {IWell} interface.
 *
 **/

contract Well is
    ERC20Permit,
    IWell,
    ImmutableTokens,
    ImmutableWellFunction,
    ImmutablePump
{
    /// @dev see {IWell.initialize}
    constructor(
        IERC20[] memory _tokens,
        Call memory _function,
        Call memory _pump,
        string memory _name,
        string memory _symbol
    )
        ERC20(_name, _symbol)
        ERC20Permit(_name)
        ImmutableTokens(_tokens)
        ImmutableWellFunction(_function)
        ImmutablePump(_pump)
    {
        if (_pump.target != address(0)) 
            IPump(_pump.target).attach(_pump.data, _tokens.length);
    }

    /// @dev see {IWell.well}
    function well() external view returns (IERC20[] memory _tokens, Call memory _wellFunction, Call memory _pump) {
        _tokens = tokens();
        _wellFunction = wellFunction();
        _pump = pump();
    }

    /// @dev see {IWell.tokens}
    function tokens()
        public
        view
        override(IWell, ImmutableTokens)
        returns (IERC20[] memory ts)
    {
        ts = ImmutableTokens.tokens();
    }

    /// @dev see {IWell.pump}
    function pump()
        public
        view
        override(IWell, ImmutablePump)
        returns (Call memory)
    {
        return ImmutablePump.pump();
    }

    /// @dev see {IWell.wellFunction}
    function wellFunction()
        public
        view
        override(IWell, ImmutableWellFunction)
        returns (Call memory)
    {
        return ImmutableWellFunction.wellFunction();
    }

    /**
     * Swap
     **/

    /// @dev see {IWell.swapFrom}
    function swapFrom(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient
    ) external returns (uint256 amountOut) {
        amountOut = uint256(
            updatePumpsAndgetSwap(
                fromToken,
                toToken,
                int256(amountIn),
                int256(minAmountOut)
            )
        );
        _executeSwap(fromToken, toToken, amountIn, amountOut, recipient);
    }

    /// @dev see {IWell.swapTo}
    function swapTo(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 maxAmountIn,
        uint256 amountOut,
        address recipient
    ) external returns (uint256 amountIn) {
        amountIn = uint256(
            -updatePumpsAndgetSwap(
                toToken,
                fromToken,
                -int256(amountOut),
                -int256(maxAmountIn)
            )
        );
        _executeSwap(fromToken, toToken, amountIn, amountOut, recipient);
    }

    /// @dev see {IWell.getSwapIn}
    function getSwapIn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amountOut
    ) external view returns (uint256 amountIn) {
        amountIn = uint256(-getSwap(toToken, fromToken, -int256(amountOut)));
    }

    /// @dev see {IWell.getSwapOut}
    function getSwapOut(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amountIn
    ) external view returns (uint256 amountOut) {
        amountOut = uint256(getSwap(fromToken, toToken, int256(amountIn)));
    }

    /// @dev low level swap function. Fetches balances, indexes of tokens and returns swap output.
    /// given a change in balance of iToken, returns change in balance of jToken.
    function getSwap(
        IERC20 iToken,
        IERC20 jToken,
        int256 dXi
    ) public view returns (int256 dXj) {
        IERC20[] memory _tokens = tokens();
        uint256[] memory balances = getBalances(_tokens);
        (uint256 i, uint256 j) = getIJ(_tokens, iToken, jToken);
        dXj = calculateSwap(balances, i, j, dXi);
    }

    /// @dev same as {getSwap}, but also updates pumps
    function updatePumpsAndgetSwap(
        IERC20 iToken,
        IERC20 jToken,
        int256 dXi,
        int256 minDx_j
    ) internal returns (int256 dXj) {
        IERC20[] memory _tokens = tokens();
        uint256[] memory balances = pumpBalances(_tokens);
        (uint256 i, uint256 j) = getIJ(_tokens, iToken, jToken);
        dXj = calculateSwap(balances, i, j, dXi);
        require(dXj >= minDx_j, "Well: slippage");
    }

    /// @dev contains core swap logic.
    /// A swap to a specified amount is the same as a swap from a negative specified amount.
    /// Thus, swapFrom and swapTo can use the same swap logic using signed math.
    function calculateSwap(
        uint256[] memory xs,
        uint256 i,
        uint256 j,
        int256 dXi
    ) public view returns (int256 dXj) {
        Call memory _wellFunction = wellFunction();
        uint256 d = getLpTokenSupply(_wellFunction, xs);
        xs[i] = dXi > 0 ? xs[i] + uint256(dXi) : xs[i] - uint256(-dXi);
        dXj = int256(xs[j]) - int256(getBalance(_wellFunction, xs, j, d));
    }

    /// @dev executes token transfers and emits Swap event.
    function _executeSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amountIn,
        uint256 amountOut,
        address recipient
    ) internal {
        fromToken.transferFrom(msg.sender, address(this), amountIn);
        toToken.transfer(recipient, amountOut);
        emit Swap(fromToken, toToken, amountIn, amountOut);
    }

    /**
     * Add Liquidity
     **/

    /// @dev see {IWell.addLiquidity}
    function addLiquidity(
        uint256[] memory tokenAmountsIn,
        uint256 minAmountOut,
        address recipient
    ) external returns (uint256 amountOut) {
        IERC20[] memory _tokens = tokens();
        uint256[] memory balances = pumpBalances(_tokens);
        for (uint256 i; i < _tokens.length; ++i) {
            _tokens[i].transferFrom(
                msg.sender,
                address(this),
                tokenAmountsIn[i]
            );
            balances[i] = balances[i] + tokenAmountsIn[i];
        }
        amountOut = getLpTokenSupply(wellFunction(), balances) - totalSupply();
        require(amountOut >= minAmountOut, "Well: slippage");
        _mint(recipient, amountOut);
        emit AddLiquidity(tokenAmountsIn, amountOut);
    }

    /// @dev see {IWell.getAddLiquidityOut}
    function getAddLiquidityOut(uint256[] memory tokenAmountsIn)
        external
        view
        returns (uint256 amountOut)
    {
        IERC20[] memory _tokens = tokens();
        uint256[] memory balances = getBalances(_tokens);
        for (uint256 i; i < _tokens.length; ++i)
            balances[i] = balances[i] + tokenAmountsIn[i];
        amountOut = getLpTokenSupply(wellFunction(), balances) - totalSupply();
    }

    /**
     * Remove Liquidity
     **/

    /// @dev see {IWell.removeLiquidity}
    function removeLiquidity(
        uint256 lpAmountIn,
        uint256[] calldata minTokenAmountsOut,
        address recipient
    ) external returns (uint256[] memory tokenAmountsOut) {
        IERC20[] memory _tokens = tokens();
        uint256[] memory balances = pumpBalances(_tokens);
        uint256 d = totalSupply();
        tokenAmountsOut = new uint256[](_tokens.length);
        _burn(msg.sender, lpAmountIn);
        for (uint256 i; i < _tokens.length; ++i) {
            tokenAmountsOut[i] = (lpAmountIn * balances[i]) / d;
            require(
                tokenAmountsOut[i] >= minTokenAmountsOut[i],
                "Well: slippage"
            );
            _tokens[i].transfer(recipient, tokenAmountsOut[i]);
        }
        emit RemoveLiquidity(lpAmountIn, tokenAmountsOut);
    }

    /// @dev see {IWell.getRemoveLiquidityOut}
    function getRemoveLiquidityOut(uint256 lpAmountIn)
        external
        view
        returns (uint256[] memory tokenAmountsOut)
    {
        IERC20[] memory _tokens = tokens();
        uint256[] memory balances = getBalances(_tokens);
        uint256 d = totalSupply();
        tokenAmountsOut = new uint256[](_tokens.length);
        for (uint256 i; i < _tokens.length; ++i) {
            tokenAmountsOut[i] = (lpAmountIn * balances[i]) / d;
        }
    }

    /**
     * Remove Liquidity One Token
     **/

    /// @dev see {IWell.removeLiquidityOneToken}
    function removeLiquidityOneToken(
        IERC20 token,
        uint256 lpAmountIn,
        uint256 minTokenAmountOut,
        address recipient
    ) external returns (uint256 tokenAmountOut) {
        IERC20[] memory _tokens = tokens();
        uint256[] memory balances = pumpBalances(_tokens);
        tokenAmountOut = _getRemoveLiquidityOneTokenOut(
            _tokens,
            token,
            balances,
            lpAmountIn
        );
        require(tokenAmountOut >= minTokenAmountOut, "Well: slippage");

        _burn(msg.sender, lpAmountIn);
        token.transfer(recipient, tokenAmountOut);
        emit RemoveLiquidityOneToken(lpAmountIn, token, tokenAmountOut);

        // todo: decide on event signature.
        // uint256[] memory tokenAmounts = new uint256[](w.tokens.length);
        // tokenAmounts[i] = tokenAmountOut;
        // emit RemoveLiquidity(lpAmountIn, tokenAmounts);
    }

    /// @dev see {IWell.getRemoveLiquidityOneTokenOut}
    function getRemoveLiquidityOneTokenOut(IERC20 token, uint256 lpAmountIn)
        external
        view
        returns (uint256 tokenAmountOut)
    {
        IERC20[] memory _tokens = tokens();
        uint256[] memory balances = getBalances(_tokens);
        tokenAmountOut = _getRemoveLiquidityOneTokenOut(
            _tokens,
            token,
            balances,
            lpAmountIn
        );
    }

    function _getRemoveLiquidityOneTokenOut(
        IERC20[] memory _tokens,
        IERC20 token,
        uint256[] memory balances,
        uint256 lpAmountIn
    ) private view returns (uint256 tokenAmountOut) {
        uint256 j = getJ(_tokens, token);
        uint256 newD = totalSupply() - lpAmountIn;
        uint256 newXj = getBalance(wellFunction(), balances, j, newD);
        tokenAmountOut = balances[j] - newXj;
    }

    /**
     * Remove Liquidity Imbalanced
     **/

    /// @dev see {IWell.removeLiquidityImbalanced}
    function removeLiquidityImbalanced(
        uint256 maxLpAmountIn,
        uint256[] calldata tokenAmountsOut,
        address recipient
    ) external returns (uint256 lpAmountIn) {
        IERC20[] memory _tokens = tokens();
        uint256[] memory balances = pumpBalances(_tokens);
        lpAmountIn = _getRemoveLiquidityImbalanced(
            _tokens,
            balances,
            tokenAmountsOut
        );
        require(lpAmountIn <= maxLpAmountIn, "Well: slippage");
        _burn(msg.sender, lpAmountIn);
        for (uint256 i; i < _tokens.length; ++i)
            _tokens[i].transfer(recipient, tokenAmountsOut[i]);
        emit RemoveLiquidity(lpAmountIn, tokenAmountsOut);
    }

    /// @dev see {IWell.getRemoveLiquidityImbalanced}
    function getRemoveLiquidityImbalanced(uint256[] calldata tokenAmountsOut)
        external
        view
        returns (uint256 lpAmountIn)
    {
        IERC20[] memory _tokens = tokens();
        uint256[] memory balances = getBalances(_tokens);
        lpAmountIn = _getRemoveLiquidityImbalanced(
            _tokens,
            balances,
            tokenAmountsOut
        );
    }

    function _getRemoveLiquidityImbalanced(
        IERC20[] memory _tokens,
        uint256[] memory balances,
        uint256[] calldata tokenAmountsOut
    ) private view returns (uint256) {
        for (uint256 i; i < _tokens.length; ++i)
            balances[i] = balances[i] - tokenAmountsOut[i];
        return totalSupply() - getLpTokenSupply(wellFunction(), balances);
    }

    /// @dev returns the balances of the well and updates the pumps
    function pumpBalances(IERC20[] memory _tokens)
        internal
        returns (uint256[] memory balances)
    {
        balances = getBalances(_tokens);
        updatePump(balances);
    }

    /// @dev updates the pumps with the previous balances
    function updatePump(uint256[] memory balances)
        internal
    {
        if (pumpAddress() != address(0))
            IPump(pumpAddress()).update(pumpBytes(), balances);
    }

    /// @dev returns the balances of the tokens by calling balanceOf on each token
    function getBalances(IERC20[] memory _tokens)
        internal
        view
        returns (uint256[] memory balances)
    {
        balances = new uint256[](_tokens.length);
        for (uint256 i; i < _tokens.length; ++i)
            balances[i] = _tokens[i].balanceOf(address(this));
    }

    /// @dev gets the jth balance given a list of balances and LP token supply.
    /// wraps the getLpTokenSupply function in the well function contract
    function getLpTokenSupply(Call memory _wellFunction, uint256[] memory balances)
        internal
        view
        returns (uint256 d)
    {
        d = IWellFunction(_wellFunction.target).getLpTokenSupply(_wellFunction.data, balances);
    }

    /// @dev gets the LP token supply given a list of balances.
    /// wraps the getBalance function in the well function contract
    function getBalance(
        Call memory wf,
        uint256[] memory balances,
        uint256 j,
        uint256 lpTokenSupply
    ) internal view returns (uint256 x) {
        x = IWellFunction(wf.target).getBalance(wf.data, balances, j, lpTokenSupply);
    }

    /// @dev returns the index of fromToken and toToken in tokens
    function getIJ(
        IERC20[] memory _tokens,
        IERC20 iToken,
        IERC20 jToken
    ) internal pure returns (uint256 i, uint256 j) {
        for (uint256 k; k < _tokens.length; ++k) {
            if (iToken == _tokens[i]) i = k;
            else if (jToken == _tokens[i]) j = k;
        }
    }

    /// @dev returns the index of token in tokens
    function getJ(IERC20[] memory _tokens, IERC20 iToken)
        internal
        pure
        returns (uint256 i)
    {
        for (uint256 k; k < _tokens.length; ++k)
            if (iToken == _tokens[i]) return k;
    }
}
