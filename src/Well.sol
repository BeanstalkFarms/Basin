/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "oz/security/ReentrancyGuard.sol";
import "oz/token/ERC20/extensions/draft-ERC20Permit.sol";
import "oz/token/ERC20/utils/SafeERC20.sol";

import "src/interfaces/IWell.sol";
import "src/interfaces/IPump.sol";
import "src/interfaces/IWellFunction.sol";

import "src/utils/ImmutableTokens.sol";
import "src/utils/ImmutablePump.sol";
import "src/utils/ImmutableWellFunction.sol";

/**
 * @title Well
 * @author Publius, Silo Chad
 * @dev A Well is a constant function AMM allowing the provisioning of liquidity
 * into a single pooled on-chain liquidity position.
 * 
 * Each Well is defined by its Tokens, Well function, and Pump.
 * - **Tokens** define the set of ERC-20 tokens that can be exchanged in the Well.
 * - The **Well function** defines an invariant relationship between the balances
 *   of the tokens in the Well and the number of LP tokens. See {IWellFunction}.
 * - **Pumps** are on-chain oracles that are updated every time the Well is
 *   interacted with. See {IPump}.
 * 
 * A Well's Tokens, Well function, and Pump are stored as immutable variables
 * during Well construction to prevent unnessary SLOAD calls during operation.
 *
 * Wells support swapping, adding liquidity, and removing liquidity in balanced
 * or imbalanced proportions.
 * 
 * Wells are stateless beyond the issuance of an ERC-20 LP token. The balance of
 * tokens in the Well is read directly from each token's {IERC20-balanceOf} method.
 * Well functions and Pumps can independently choose to be stateful or stateless.
 *
 * Including a Pump is optional. Only 1 Pump can be attached to a Well, but a
 * Pump can call other Pumps, allowing multiple Pumps to be used.
 *
 * Each Well implements ERC-20, ERC-2612 and the {IWell} interface.
 */
contract Well is
    ERC20Permit,
    IWell,
    ImmutableTokens,
    ImmutableWellFunction,
    ImmutablePump,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    /**
     * @dev Construct a Well. Each Well is defined by its combination of
     * ERC20 tokens (`_tokens`), Well function (`_function`), and Pump (`_pump`). 
     *
     * For gas efficiency, these three components are placed in immutable
     * storage during construction. 
     * 
     * {ImmutableTokens} stores up to 16 immutable token addresses.
     * {ImmutableWellFunction} stores an immutable Well function {Call} struct.
     * {ImmutablePump} stores an immutable Pump {Call} struct.
     *
     * Usage of a Pump is optional: set `_pump.target` to address(0) to disable.
     */
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
        ReentrancyGuard()
    {
        if (_pump.target != address(0)) 
            IPump(_pump.target).attach(_tokens.length, _pump.data);
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
     * @dev See {IWell.pump}
     */
    function pump()
        public
        view
        override(IWell, ImmutablePump)
        returns (Call memory)
    {
        return ImmutablePump.pump();
    }

    /**
     * @dev See {IWell.well}
     */
    function well() external view returns (
        IERC20[] memory _tokens,
        Call memory _wellFunction,
        Call memory _pump
    ) {
        _tokens = tokens();
        _wellFunction = wellFunction();
        _pump = pump();
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
        amountOut = uint(
            updatePumpsAndgetSwap(
                fromToken,
                toToken,
                int(amountIn),
                int(minAmountOut)
            )
        );
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
        amountOut = uint(getSwap(fromToken, toToken, int(amountIn)));
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
        amountIn = uint(
            -updatePumpsAndgetSwap(
                toToken,
                fromToken,
                -int(amountOut),
                -int(maxAmountIn)
            )
        );
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
        amountIn = uint(-getSwap(toToken, fromToken, -int(amountOut)));
    }

    //////////// SWAP: UTILITIES ////////////

    /**
     * @dev See {IWell.getSwap}.
     *
     * A swap to a specified amount is the same as a swap from a negative
     * specified amount. Allows {swapFrom} and {swapTo} to employ the same Swap
     * logic using signed math.
     * 
     * Accounting is performed from the perspective of the Well. Positive 
     * values represent token flows into the Well, negative values represent 
     * token flows out of the Well.
     * 
     * | `fromToken` | `toToken` | `amountIn` | `amountOut` | Note                              |
     * |-------------|-----------|------------|-------------|-----------------------------------|
     * | 0xBEAN      | 0xDAI     | 100 BEAN   | -100 DAI    | User spends BEAN and receives DAI |
     * | 0xBEAN      | 0xDAI     | -100 BEAN  | 100 DAI     | User spends DAI and receives BEAN |
     * | 0xDAI       | 0xBEAN    | 100 DAI    | -100 BEAN   | User spends DAI and receives BEAN |
     * | 0xDAI       | 0xBEAN    | -100 DAI   | 100 BEAN    | User spends BEAN and receives DAI |
     *
     * Conversion back to uint256 should occur in upstream {getSwapFrom} and
     * {getSwapTo} methods.
     */
    function getSwap(
        IERC20 fromToken,
        IERC20 toToken,
        int amountIn
    ) public view returns (int amountOut) {
        IERC20[] memory _tokens = tokens();
        uint[] memory balances = getBalances(_tokens);
        (uint i, uint j) = getIJ(_tokens, fromToken, toToken);
        amountOut = calculateSwap(balances, i, j, amountIn);
    }
    
    /**
     * @dev See {IWell.calculateSwap}.
     * 
     * During Well operation, `balances` are loaded prior prior to this function.
     * It is exposed publicly to allow Well consumers to calculate swap rates
     * for any given set of token balances.
     * 
     * For both `amountIn` and `amountOut`, positive values indicate a token 
     * inflow to the Well, and negative values indicate a token outflow.
     */
    function calculateSwap(
        uint[] memory balances,
        uint i,
        uint j,
        int amountIn
    ) public view returns (int amountOut) {
        Call memory _wellFunction = wellFunction();
        balances[i] = amountIn > 0
            ? balances[i] + uint(amountIn)
            : balances[i] - uint(-amountIn);
        amountOut = int(balances[j]) - int(getBalance(_wellFunction, balances, j, totalSupply()));
    }

    /**
     * @dev Internal version of {getSwap} which also updates the Pump.
     */
    function updatePumpsAndgetSwap(
        IERC20 fromToken,
        IERC20 toToken,
        int amountIn,
        int minAmountOut
    ) internal returns (int amountOut) {
        IERC20[] memory _tokens = tokens();
        uint[] memory balances = updatePumpBalances(_tokens);
        (uint i, uint j) = getIJ(_tokens, fromToken, toToken);
        amountOut = calculateSwap(balances, i, j, amountIn);
        require(amountOut >= minAmountOut, "Well: slippage");
    }

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
        toToken.transfer(recipient, amountOut);
        emit Swap(fromToken, toToken, amountIn, amountOut);
    }

    //////////// ADD LIQUIDITY ////////////

    /**
     * @dev See {IWell.addLiquidity}
     */
    function addLiquidity(
        uint[] memory tokenAmountsIn,
        uint minLpAmountOut,
        address recipient
    ) external nonReentrant returns (uint lpAmountOut) {
        IERC20[] memory _tokens = tokens();
        uint[] memory balances = updatePumpBalances(_tokens);
        for (uint i; i < _tokens.length; ++i) {
            if (tokenAmountsIn[i] == 0) continue;
            _tokens[i].safeTransferFrom(
                msg.sender,
                address(this),
                tokenAmountsIn[i]
            );
            balances[i] = balances[i] + tokenAmountsIn[i];
        }
        lpAmountOut = getLpTokenSupply(wellFunction(), balances) - totalSupply();
        require(lpAmountOut >= minLpAmountOut, "Well: slippage");
        _mint(recipient, lpAmountOut);
        emit AddLiquidity(tokenAmountsIn, lpAmountOut);
    }

    /**
     * @dev See {IWell.getAddLiquidityOut}
     */
    function getAddLiquidityOut(uint[] memory tokenAmountsIn)
        external
        view
        returns (uint lpAmountOut) // lpAmountOut
    {
        IERC20[] memory _tokens = tokens();
        uint[] memory balances = getBalances(_tokens);
        for (uint i; i < _tokens.length; ++i)
            balances[i] = balances[i] + tokenAmountsIn[i];
        lpAmountOut = getLpTokenSupply(wellFunction(), balances) - totalSupply();
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
        uint[] memory balances = updatePumpBalances(_tokens);
        uint lpTokenSupply = totalSupply();
        tokenAmountsOut = new uint[](_tokens.length);
        _burn(msg.sender, lpAmountIn);
        for (uint i; i < _tokens.length; ++i) {
            tokenAmountsOut[i] = (lpAmountIn * balances[i]) / lpTokenSupply;
            require(
                tokenAmountsOut[i] >= minTokenAmountsOut[i],
                "Well: slippage"
            );
            _tokens[i].transfer(recipient, tokenAmountsOut[i]);
        }
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
        uint[] memory balances = getBalances(_tokens);
        uint lpTokenSupply = totalSupply();
        tokenAmountsOut = new uint[](_tokens.length);
        for (uint i; i < _tokens.length; ++i) {
            tokenAmountsOut[i] = (lpAmountIn * balances[i]) / lpTokenSupply;
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
        uint[] memory balances = updatePumpBalances(_tokens);
        tokenAmountOut = _getRemoveLiquidityOneTokenOut(
            _tokens,
            tokenOut,
            balances,
            lpAmountIn
        );
        require(tokenAmountOut >= minTokenAmountOut, "Well: slippage");

        _burn(msg.sender, lpAmountIn);
        tokenOut.transfer(recipient, tokenAmountOut);
        emit RemoveLiquidityOneToken(lpAmountIn, tokenOut, tokenAmountOut);

        // todo: decide on event signature.
        // uint[] memory tokenAmounts = new uint[](w.tokens.length);
        // tokenAmounts[i] = tokenAmountOut;
        // emit RemoveLiquidity(lpAmountIn, tokenAmounts);
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
        uint[] memory balances = getBalances(_tokens);
        tokenAmountOut = _getRemoveLiquidityOneTokenOut(
            _tokens,
            tokenOut,
            balances,
            lpAmountIn
        );
    }

    /**
     * @dev TODO
     */
    function _getRemoveLiquidityOneTokenOut(
        IERC20[] memory _tokens,
        IERC20 token,
        uint[] memory balances,
        uint lpAmountIn
    ) private view returns (uint tokenAmountOut) {
        uint j = getJ(_tokens, token);
        uint newLpTokenSupply = totalSupply() - lpAmountIn;
        uint newBalanceJ = getBalance(
            wellFunction(),
            balances,
            j,
            newLpTokenSupply
        );
        tokenAmountOut = balances[j] - newBalanceJ;
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
        uint[] memory balances = updatePumpBalances(_tokens);
        lpAmountIn = _getRemoveLiquidityImbalanced(
            _tokens,
            balances,
            tokenAmountsOut
        );
        require(lpAmountIn <= maxLpAmountIn, "Well: slippage");
        _burn(msg.sender, lpAmountIn);
        for (uint i; i < _tokens.length; ++i)
            _tokens[i].transfer(recipient, tokenAmountsOut[i]);
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
        uint[] memory balances = getBalances(_tokens);
        lpAmountIn = _getRemoveLiquidityImbalanced(
            _tokens,
            balances,
            tokenAmountsOut
        );
    }

    /**
     * @dev TODO
     */
    function _getRemoveLiquidityImbalanced(
        IERC20[] memory _tokens,
        uint[] memory balances,
        uint[] calldata tokenAmountsOut
    ) private view returns (uint) {
        for (uint i; i < _tokens.length; ++i)
            balances[i] = balances[i] - tokenAmountsOut[i];
        return totalSupply() - getLpTokenSupply(wellFunction(), balances);
    }

    //////////// UPDATE PUMP ////////////

    /**
     * @dev Fetches the current token balances of the Well and updates the Pump.
     * Typically called before an operation that modifies the Well's balances.
     */
    function updatePumpBalances(IERC20[] memory _tokens)
        internal
        returns (uint[] memory balances)
    {
        balances = getBalances(_tokens);
        if (pumpAddress() != address(0))
            IPump(pumpAddress()).update(balances, pumpBytes());
    }

    //////////// BALANCE OF WELL TOKENS & LP TOKEN ////////////

    /**
     * @dev Returns the Well's balances of `_tokens` by calling the ERC-20 
     * {balanceOf} method on each token.
     */
    function getBalances(IERC20[] memory _tokens)
        internal
        view
        returns (uint[] memory balances)
    {
        balances = new uint[](_tokens.length);
        for (uint i; i < _tokens.length; ++i)
            balances[i] = _tokens[i].balanceOf(address(this));
    }

    /**
     * @dev  Gets the LP token supply given a list of `balances` from the provided
     * `_wellFunction`. Wraps {IWellFunction.getLpTokenSupply}.
     *
     * The Well function is passed as a parameter to minimize gas in instances
     * where it is called multiple times in one transaction.
     */
    function getLpTokenSupply(Call memory _wellFunction, uint[] memory balances)
        internal
        view
        returns (uint lpTokenSupply)
    {
        lpTokenSupply = IWellFunction(_wellFunction.target).getLpTokenSupply(
            balances,
            _wellFunction.data
        );
    }

    /**
     * @dev Gets the `j`th balance given a list of `balances` and `lpTokenSupply`
     * from the provided `_wellFunction`. Wraps {IWellFunction.getBalance}.
     * 
     * The Well function is passed as a parameter to minimize gas in instances
     * where it is called multiple times in one transaction.
     */
    function getBalance(
        Call memory _wellFunction,
        uint[] memory balances,
        uint j,
        uint lpTokenSupply
    ) internal view returns (uint balance) {
        balance = IWellFunction(_wellFunction.target).getBalance(
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
    function getIJ(
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
    function getJ(IERC20[] memory _tokens, IERC20 jToken)
        internal
        pure
        returns (uint j)
    {
        for (j; jToken != _tokens[j]; ++j) {}
    }
}
