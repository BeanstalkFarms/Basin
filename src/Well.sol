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

import "src/utils/ByteStorage.sol";
import "src/utils/ImmutableTokens.sol";
import "src/utils/ImmutablePumps.sol";
import "src/utils/ImmutableWellFunction.sol";

/**
 * @title Well
 * @author Publius, Silo Chad, Brean
 * @dev A Well is a constant function AMM allowing the provisioning of liquidity
 * into a single pooled on-chain liquidity position.
 */
contract Well is
    ByteStorage,
    ERC20Permit,
    IWell,
    ImmutableTokens,
    ImmutableWellFunction,
    ImmutablePumps,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    bytes32 constant BALANCES_STORAGE_SLOT = keccak256("balances.storage.slot");

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
        IERC20[] memory _tokens,
        Call memory _function,
        Call[] memory _pumps,
        string memory _name,
        string memory _symbol
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
     * @dev See {IWell.well}
     */
    function well() external view returns (
        IERC20[] memory _tokens,
        Call memory _wellFunction,
        Call[] memory _pumps
    ) {
        _tokens = tokens();
        _wellFunction = wellFunction();
        _pumps = pumps();
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
            _getSwapAndUpdatePumps(
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
            -_getSwapAndUpdatePumps(
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
        uint[] memory balances = getBalances(_tokens.length);
        (uint i, uint j) = getIJ(_tokens, fromToken, toToken);
        balances[i] = amountIn > 0
            ? balances[i] + uint(amountIn)
            : balances[i] - uint(-amountIn);
        // Note: The rounding approach of the Well function determines whether
        // slippage from imprecision goes to the Well or to the User.
        amountOut = int(balances[j]) - int(getBalance(wellFunction(), balances, j, totalSupply()));
    }

    /**
     * @dev Internal version of {getSwap} which also updates the Pump.
     */
    function _getSwapAndUpdatePumps(
        IERC20 fromToken,
        IERC20 toToken,
        int amountIn,
        int minAmountOut
    ) internal returns (int amountOut) {
        IERC20[] memory _tokens = tokens();
        uint[] memory balances = updatePumpBalances(_tokens.length); // pumps?
        (uint i, uint j) = getIJ(_tokens, fromToken, toToken);
        balances[i] = amountIn > 0
            ? balances[i] + uint(amountIn)
            : balances[i] - uint(-amountIn);

        int balanceJBefore = int(balances[j]);
        // Note: The rounding approach of the Well function determines whether
        // slippage from imprecision goes to the Well or to the User.
        balances[j] = getBalance(wellFunction(), balances, j, totalSupply());
        amountOut = balanceJBefore - int(balances[j]);
        require(amountOut >= minAmountOut, "Well: slippage");
        setBalances(balances);
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
        uint[] memory balances = updatePumpBalances(_tokens.length);
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
        setBalances(balances);
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
        uint[] memory balances = getBalances(_tokens.length);
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
        uint[] memory balances = updatePumpBalances(_tokens.length);
        uint lpTokenSupply = totalSupply();
        tokenAmountsOut = new uint[](_tokens.length);
        _burn(msg.sender, lpAmountIn);
        for (uint i; i < _tokens.length; ++i) {
            tokenAmountsOut[i] = (lpAmountIn * balances[i]) / lpTokenSupply;
            require(
                tokenAmountsOut[i] >= minTokenAmountsOut[i],
                "Well: slippage"
            );
            _tokens[i].safeTransfer(recipient, tokenAmountsOut[i]);
            balances[i] = balances[i] - tokenAmountsOut[i];
        }
        setBalances(balances);
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
        uint[] memory balances = getBalances(_tokens.length);
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
        uint[] memory balances = updatePumpBalances(_tokens.length);
        uint j = getJ(_tokens, tokenOut);
        tokenAmountOut = _getRemoveLiquidityOneTokenOut(
            j,
            balances,
            lpAmountIn
        );
        require(tokenAmountOut >= minTokenAmountOut, "Well: slippage");

        _burn(msg.sender, lpAmountIn);
        tokenOut.safeTransfer(recipient, tokenAmountOut);

        balances[j] = balances[j] - tokenAmountOut;
        setBalances(balances);

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
        uint[] memory balances = getBalances(_tokens.length);
        uint j = getJ(_tokens, tokenOut);
        tokenAmountOut = _getRemoveLiquidityOneTokenOut(
            j,
            balances,
            lpAmountIn
        );
    }

    /**
     * @dev TODO
     */
    function _getRemoveLiquidityOneTokenOut(
        uint j,
        uint[] memory balances,
        uint lpAmountIn
    ) private view returns (uint tokenAmountOut) {
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
        uint[] memory balances = updatePumpBalances(_tokens.length);
        for (uint i; i < _tokens.length; ++i) {
            _tokens[i].safeTransfer(recipient, tokenAmountsOut[i]);
            balances[i] = balances[i] - tokenAmountsOut[i];
        }
        lpAmountIn = totalSupply() - getLpTokenSupply(wellFunction(), balances);
        require(lpAmountIn <= maxLpAmountIn, "Well: slippage");
        _burn(msg.sender, lpAmountIn);
        setBalances(balances);
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
        uint[] memory balances = getBalances(_tokens.length);
        for (uint i; i < _tokens.length; ++i)
            balances[i] = balances[i] - tokenAmountsOut[i];
        return totalSupply() - getLpTokenSupply(wellFunction(), balances);
    }

    //////////// UPDATE PUMP ////////////

    /**
     * @dev Fetches the current token balances of the Well and updates the Pumps.
     * Typically called before an operation that modifies the Well's balances.
     */
    function updatePumpBalances(uint numberOfTokens)
        internal
        returns (uint[] memory balances)
    {
        balances = getBalances(numberOfTokens);

        // TODO: experiment with this
        if (numberOfPumps() == 0) return balances;

        if (numberOfPumps() == 1) {
            IPump(firstPumpAddress()).update(balances, firstPumpBytes());
        } else {
            Call[] memory _pumps = pumps();
            for (uint i; i < _pumps.length; ++i) {
                IPump(_pumps[i].target).update(balances, _pumps[i].data);
            }
        }
    }

    //////////// BALANCE OF WELL TOKENS & LP TOKEN ////////////

    /**
     * @dev Returns the Well's balances of tokens by reading from byte storage.
     */
    function getBalances(uint numberOfTokens)
        internal
        view
        returns (uint[] memory balances)
    {
        balances = readUint128(BALANCES_STORAGE_SLOT, numberOfTokens);
    }

    /**
     * @dev Sets the Well's balances of tokens by writing to byte storage.
     */
    function setBalances(uint[] memory balances)
        internal
    {
        storeUint128(BALANCES_STORAGE_SLOT, balances);
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
