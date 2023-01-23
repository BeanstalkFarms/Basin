/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import {ReentrancyGuard} from "oz/security/ReentrancyGuard.sol";
import {ERC20, ERC20Permit} from "oz/token/ERC20/extensions/draft-ERC20Permit.sol";
import {IERC20, SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";

import {IWell, Call} from "src/interfaces/IWell.sol";
import {IPump} from "src/interfaces/IPump.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";

import {LibBytes} from "src/libraries/LibBytes.sol";

import {ImmutableTokens} from "src/utils/ImmutableTokens.sol";
import {ImmutablePumps} from "src/utils/ImmutablePumps.sol";
import {ImmutableWellFunction} from "src/utils/ImmutableWellFunction.sol";

/**
 * @title Well
 * @author Publius, Silo Chad, Brean
 * @dev A Well is a constant function AMM allowing the provisioning of liquidity
 * into a single pooled on-chain liquidity position.
 */
contract Well is
    ERC20Permit,
    IWell,
    ImmutableTokens,
    ImmutableWellFunction,
    ImmutablePumps,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    bytes32 constant RESERVES_STORAGE_SLOT = keccak256("reserves.storage.slot");

    address immutable __auger;

    /**
     * @dev Construct a Well. Each Well is defined by its combination of
     * ERC20 tokens (`_tokens`), Well function (`_function`), and Pump (`_pump`). 
     *
     * For gas efficiency, these three components are placed in immutable
     * storage during construction. 
     * 
     * {ImmutableTokens} stores up to 4 immutable token addresses.
     * {ImmutableWellFunction} stores an immutable Well function {Call} struct.
     * {ImmutablePump} stores up to 4 immutable Pump {Call[]} structs.
     *
     * Usage of Pumps is optional: set `_pumps.length` to 0 to disable.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        IERC20[] memory _tokens,
        Call memory _function,
        Call[] memory _pumps
    )
        ERC20(_name, _symbol)
        ERC20Permit(_name)
        ImmutableTokens(_tokens)
        ImmutableWellFunction(_function)
        ImmutablePumps(_pumps)
        ReentrancyGuard()
    {
        for (uint i; i < _pumps.length; ++i) {
            IPump(_pumps[i].target).attach(_tokens.length, _pumps[i].data);
        }
        __auger = msg.sender;
    }

    //////////// WELL DEFINITION ////////////

    /**
     * @dev See {IWell.tokens}
     */
    function tokens()
        public
        view
        override(IWell, ImmutableTokens)
        returns (IERC20[] memory ts)
    {
        ts = ImmutableTokens.tokens();
    }

    /**
     * @dev See {IWell.wellFunction}
     */
    function wellFunction()
        public
        view
        override(IWell, ImmutableWellFunction)
        returns (Call memory)
    {
        return ImmutableWellFunction.wellFunction();
    }

    /**
     * @dev See {IWell.pumps}
     */
    function pumps()
        public
        view
        override(IWell, ImmutablePumps)
        returns (Call[] memory)
    {
        return ImmutablePumps.pumps();
    }

    /**
     * @dev See {IWell.auger}
     */
    function auger() external view override returns (address) {
        return __auger;
    }

    /**
     * @dev See {IWell.well}
     */
    function well() external view returns (
        IERC20[] memory _tokens,
        Call memory _wellFunction,
        Call[] memory _pumps,
        address _auger
    ) {
        _tokens = tokens();
        _wellFunction = wellFunction();
        _pumps = pumps();
        _auger = __auger;
    }

    //////////// SWAP: FROM ////////////

    /**
     * @dev See {IWell.swapFrom}
     */
    function swapFrom(
        IERC20 fromToken,
        IERC20 toToken,
        uint amountIn,
        uint minAmountOut,
        address recipient
    ) external nonReentrant returns (uint amountOut) {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _updatePumps(_tokens.length);
        (uint i, uint j) = _getIJ(_tokens, fromToken, toToken);

        reserves[i] += amountIn;
        uint reserveJBefore = reserves[j];
        reserves[j] = _calcReserve(wellFunction(), reserves, j, totalSupply());

        // Note: The rounding approach of the Well function determines whether
        // slippage from imprecision goes to the Well or to the User.
        amountOut = reserveJBefore - reserves[j];

        require(amountOut >= minAmountOut, "Well: slippage");
        _setReserves(reserves);
        _executeSwap(fromToken, toToken, amountIn, amountOut, recipient);
    }

    /**
     * @dev See {IWell.getSwapOut}
     */
    function getSwapOut(
        IERC20 fromToken,
        IERC20 toToken,
        uint amountIn
    ) external view returns (uint amountOut) {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _getReserves(_tokens.length);
        (uint i, uint j) = _getIJ(_tokens, fromToken, toToken);

        reserves[i] += amountIn;

        // underflow is desired; Well Function SHOULD NOT increase reserves of both `i` and `j`
        amountOut = reserves[j] - _calcReserve(wellFunction(), reserves, j, totalSupply());
    }

    //////////// SWAP: TO ////////////

    /**
     * @dev See {IWell.swapTo}
     */
    function swapTo(
        IERC20 fromToken,
        IERC20 toToken,
        uint maxAmountIn,
        uint amountOut,
        address recipient
    ) external nonReentrant returns (uint amountIn) {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _updatePumps(_tokens.length);
        (uint i, uint j) = _getIJ(_tokens, fromToken, toToken);

        reserves[j] -= amountOut;
        uint reserveIBefore = reserves[i];
        reserves[i] = _calcReserve(wellFunction(), reserves, i, totalSupply());

        // Note: The rounding approach of the Well function determines whether
        // slippage from imprecision goes to the Well or to the User.
        amountIn = reserves[i] - reserveIBefore;
        
        require(amountIn <= maxAmountIn, "Well: slippage");
        _setReserves(reserves);
        _executeSwap(fromToken, toToken, amountIn, amountOut, recipient);
    }

    /**
     * @dev See {IWell.getSwapIn}
     */
    function getSwapIn(
        IERC20 fromToken,
        IERC20 toToken,
        uint amountOut
    ) external view returns (uint amountIn) {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _getReserves(_tokens.length);
        (uint i, uint j) = _getIJ(_tokens, fromToken, toToken);

        reserves[j] -= amountOut;

        amountIn = _calcReserve(wellFunction(), reserves, i, totalSupply()) - reserves[i];
    }

    //////////// SWAP: UTILITIES ////////////

    /**
     * @dev executes token transfers and emits Swap event.
     */
    function _executeSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint amountIn,
        uint amountOut,
        address recipient
    ) internal {
        fromToken.safeTransferFrom(msg.sender, address(this), amountIn);
        toToken.safeTransfer(recipient, amountOut);
        emit Swap(fromToken, toToken, amountIn, amountOut);
    }

    //////////// ADD LIQUIDITY ////////////

    /**
     * @dev See {IWell.addLiquidity}. 
     * Gas optimization: {IWell.AddLiquidity} is emitted even if `lpAmountOut` is 0.
     */
    function addLiquidity(
        uint[] memory tokenAmountsIn,
        uint minLpAmountOut,
        address recipient
    ) external nonReentrant returns (uint lpAmountOut) {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _updatePumps(_tokens.length);

        for (uint i; i < _tokens.length; ++i) {
            if (tokenAmountsIn[i] == 0) continue;
            _tokens[i].safeTransferFrom(
                msg.sender,
                address(this),
                tokenAmountsIn[i]
            );
            reserves[i] = reserves[i] + tokenAmountsIn[i];
        }
        lpAmountOut = _calcLpTokenSupply(wellFunction(), reserves) - totalSupply();

        require(lpAmountOut >= minLpAmountOut, "Well: slippage");
        _mint(recipient, lpAmountOut);
        _setReserves(reserves);
        emit AddLiquidity(tokenAmountsIn, lpAmountOut);
    }

    /**
     * @dev See {IWell.getAddLiquidityOut}
     */
    function getAddLiquidityOut(uint[] memory tokenAmountsIn)
        external
        view
        returns (uint lpAmountOut)
    {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _getReserves(_tokens.length);
        for (uint i; i < _tokens.length; ++i) {
            reserves[i] = reserves[i] + tokenAmountsIn[i];
        }
        lpAmountOut = _calcLpTokenSupply(wellFunction(), reserves) - totalSupply();
    }

    //////////// REMOVE LIQUIDITY: BALANCED ////////////

    /**
     * @dev See {IWell.removeLiquidity}
     */
    function removeLiquidity(
        uint lpAmountIn,
        uint[] calldata minTokenAmountsOut,
        address recipient
    ) external nonReentrant returns (uint[] memory tokenAmountsOut) {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _updatePumps(_tokens.length);
        uint lpTokenSupply = totalSupply();

        tokenAmountsOut = new uint[](_tokens.length);
        _burn(msg.sender, lpAmountIn);
        for (uint i; i < _tokens.length; ++i) {
            tokenAmountsOut[i] = (lpAmountIn * reserves[i]) / lpTokenSupply;
            require(
                tokenAmountsOut[i] >= minTokenAmountsOut[i],
                "Well: slippage"
            );
            _tokens[i].safeTransfer(recipient, tokenAmountsOut[i]);
            reserves[i] = reserves[i] - tokenAmountsOut[i];
        }

        _setReserves(reserves);
        emit RemoveLiquidity(lpAmountIn, tokenAmountsOut);
    }

    /**
     * @dev See {IWell.getRemoveLiquidityOut}
     */
    function getRemoveLiquidityOut(uint lpAmountIn)
        external
        view
        returns (uint[] memory tokenAmountsOut)
    {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _getReserves(_tokens.length);
        uint lpTokenSupply = totalSupply();

        tokenAmountsOut = new uint[](_tokens.length);
        for (uint i; i < _tokens.length; ++i) {
            tokenAmountsOut[i] = (lpAmountIn * reserves[i]) / lpTokenSupply;
        }
    }

    //////////// REMOVE LIQUIDITY: ONE TOKEN ////////////

    /**
     * @dev See {IWell.removeLiquidityOneToken}
     */
    function removeLiquidityOneToken(
        uint lpAmountIn,
        IERC20 tokenOut,
        uint minTokenAmountOut,
        address recipient
    ) external nonReentrant returns (uint tokenAmountOut) {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _updatePumps(_tokens.length);
        uint j = _getJ(_tokens, tokenOut);

        tokenAmountOut = _getRemoveLiquidityOneTokenOut(
            j,
            reserves,
            lpAmountIn
        );
        require(tokenAmountOut >= minTokenAmountOut, "Well: slippage");
        _burn(msg.sender, lpAmountIn);
        tokenOut.safeTransfer(recipient, tokenAmountOut);

        reserves[j] = reserves[j] - tokenAmountOut;
        _setReserves(reserves);
        emit RemoveLiquidityOneToken(lpAmountIn, tokenOut, tokenAmountOut);
    }

    /**
     * @dev See {IWell.getRemoveLiquidityOneTokenOut}
     */
    function getRemoveLiquidityOneTokenOut(IERC20 tokenOut, uint lpAmountIn)
        external
        view
        returns (uint tokenAmountOut)
    {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _getReserves(_tokens.length);
        uint j = _getJ(_tokens, tokenOut);
        tokenAmountOut = _getRemoveLiquidityOneTokenOut(
            j,
            reserves,
            lpAmountIn
        );
    }

    /**
     * @dev Shared logic for removing a single token from liquidity.
     * Calculates change in reserve `j` given a change in LP token supply.
     * 
     * Note: `lpAmountIn` is the amount of LP the user is burning in exchange
     * for some amount of token `j`.
     */
    function _getRemoveLiquidityOneTokenOut(
        uint j,
        uint[] memory reserves,
        uint lpAmountIn
    ) private view returns (uint tokenAmountOut) {
        uint newLpTokenSupply = totalSupply() - lpAmountIn;
        uint newReserveJ = _calcReserve(
            wellFunction(),
            reserves,
            j,
            newLpTokenSupply
        );
        tokenAmountOut = reserves[j] - newReserveJ;
    }

    //////////// REMOVE LIQUIDITY: IMBALANCED ////////////

    /**
     * @dev See {IWell.removeLiquidityImbalanced}
     */
    function removeLiquidityImbalanced(
        uint maxLpAmountIn,
        uint[] calldata tokenAmountsOut,
        address recipient
    ) external nonReentrant returns (uint lpAmountIn) {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _updatePumps(_tokens.length);

        for (uint i; i < _tokens.length; ++i) {
            _tokens[i].safeTransfer(recipient, tokenAmountsOut[i]);
            reserves[i] = reserves[i] - tokenAmountsOut[i];
        }
        lpAmountIn = totalSupply() - _calcLpTokenSupply(wellFunction(), reserves);
        require(lpAmountIn <= maxLpAmountIn, "Well: slippage");
        _burn(msg.sender, lpAmountIn);

        _setReserves(reserves);
        emit RemoveLiquidity(lpAmountIn, tokenAmountsOut);
    }

    /**
     * @dev See {IWell.getRemoveLiquidityImbalancedIn}
     */
    function getRemoveLiquidityImbalancedIn(uint[] calldata tokenAmountsOut)
        external
        view
        returns (uint lpAmountIn)
    {
        IERC20[] memory _tokens = tokens();
        uint[] memory balances = _getReserves(_tokens.length);
        for (uint i; i < _tokens.length; ++i)
            balances[i] = balances[i] - tokenAmountsOut[i];
        return totalSupply() - _calcLpTokenSupply(wellFunction(), balances);
    }

    //////////// SKIM ////////////

    /**
     * @dev See {IWell.skim}
     */
    function skim(address recipient) external nonReentrant returns (uint[] memory skimAmounts) {
        IERC20[] memory _tokens = tokens();
        uint[] memory balances = _getReserves(_tokens.length);
        skimAmounts = new uint[](_tokens.length);
        for (uint i; i < _tokens.length; ++i) {
            skimAmounts[i] = _tokens[i].balanceOf(address(this)) - balances[i];
            if (skimAmounts[i] > 0) _tokens[i].safeTransfer(recipient, skimAmounts[i]);
        }
    }

    //////////// UPDATE PUMP ////////////

    /**
     * @dev Fetches the current token balances of the Well and updates the Pumps.
     * Typically called before an operation that modifies the Well's balances.
     */
    function _updatePumps(uint numberOfTokens)
        internal
        returns (uint[] memory balances)
    {
        balances = _getReserves(numberOfTokens);

        if (numberOfPumps() == 0) {
            return balances;
        }

        // gas optimization: avoid looping if there is only one pump
        if (numberOfPumps() == 1) {
            IPump(firstPumpTarget()).update(balances, firstPumpBytes());
        } else {
            Call[] memory _pumps = pumps();
            for (uint i; i < _pumps.length; ++i) {
                IPump(_pumps[i].target).update(balances, _pumps[i].data);
            }
        }
    }

    //////////// BALANCE OF WELL TOKENS & LP TOKEN ////////////

    /**
     * @dev See {IWell.getBalances}
     */
    function getBalances() external view returns (uint[] memory balances) {
        return _getReserves(numberOfTokens());
    }

    /**
     * @dev Gets the Well's token balances from byte storage.
     */
    function _getReserves(uint numberOfTokens)
        internal
        view
        returns (uint[] memory balances)
    {
        balances = LibBytes.readUint128(RESERVES_STORAGE_SLOT, numberOfTokens);
    }

    /**
     * @dev Sets the Well's balances of tokens by writing to byte storage.
     */
    function _setReserves(uint[] memory balances)
        internal
    {
        LibBytes.storeUint128(RESERVES_STORAGE_SLOT, balances);
    }

    /**
     * @dev Calculates the LP token supply given a list of `balances` from the provided
     * `_wellFunction`. Wraps {IWellFunction.calcLpTokenSupply}.
     *
     * The Well function is passed as a parameter to minimize gas in instances
     * where it is called multiple times in one transaction.
     */
    function _calcLpTokenSupply(Call memory _wellFunction, uint[] memory balances)
        internal    
        view
        returns (uint lpTokenSupply)
    {
        lpTokenSupply = IWellFunction(_wellFunction.target).calcLpTokenSupply(
            balances,
            _wellFunction.data
        );
    }

    /**
     * @dev Calculates the `j`th balance given a list of `balances` and `lpTokenSupply`
     * from the provided `_wellFunction`. Wraps {IWellFunction.getBalance}.
     * 
     * The Well function is passed as a parameter to minimize gas in instances
     * where it is called multiple times in one transaction.
     */
    function _calcReserve(
        Call memory _wellFunction,
        uint[] memory balances,
        uint j,
        uint lpTokenSupply
    ) internal view returns (uint balance) {
        balance = IWellFunction(_wellFunction.target).calcReserve(
            balances,
            j,
            lpTokenSupply,
            _wellFunction.data
        );
    }

    //////////// WELL TOKEN INDEXING ////////////

    /**
     * @dev Returns the indices of `iToken` and `jToken` in `_tokens`.
     */
    function _getIJ(
        IERC20[] memory _tokens,
        IERC20 iToken,
        IERC20 jToken
    ) internal pure returns (uint i, uint j) {
        for (uint k; k < _tokens.length; ++k) {
            if (iToken == _tokens[k]) i = k;
            else if (jToken == _tokens[k]) j = k;
        }
    }

    /**
     * @dev Returns the index of `jToken` in `_tokens`.
     */
    function _getJ(IERC20[] memory _tokens, IERC20 jToken)
        internal
        pure
        returns (uint j)
    {
        for (j; jToken != _tokens[j]; ++j) {}
    }
}
