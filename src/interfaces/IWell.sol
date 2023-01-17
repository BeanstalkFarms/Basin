/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "oz/token/ERC20/IERC20.sol";

/**
 * @title Call is the struct that contains the target address and extra calldata of a generic call
 **/
struct Call {
    address target; // The address the call is executed on.
    bytes data; // Extra calldata to be passed to the call
}

/**
 * @title IWell is the interface for the Well contract
 **/
interface IWell {

    /**
     * @notice Emitted when a Swap occurs.
     * @param fromToken The token swapped from
     * @param toToken The token swapped to
     * @param amountIn The amount of `fromToken` added to the Well
     * @param amountOut The amount of `toToken` received from the Well
     */
    event Swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint amountIn,
        uint amountOut
    );

    /**
     * @notice Emitted when liquidity is added to the Well.
     * @param tokenAmountsIn The amount of each token added to the Well
     * @param lpAmountOut The amount of LP tokens minted
     */
    event AddLiquidity(
        uint[] tokenAmountsIn,
        uint lpAmountOut
    );

    /**
     * @notice Emitted when liquidity is removed from the Well.
     * @param lpAmountIn The amount of LP tokens burned
     * @param tokenAmountsOut The amounts of each token received from the Well
     * @dev Gas cost scales with `n` tokens.
     */
    event RemoveLiquidity(
        uint lpAmountIn,
        uint[] tokenAmountsOut
    );
    
    /**
     * @notice Emitted when liquidity is removed from the Well as a single token.
     * @param lpAmountIn The amount of LP tokens burned
     * @param tokenOut The token received
     * @param tokenAmountOut The amount of `tokenOut` received
     * @dev Emitting a separate event when removing liquidity to a single token
     * saves gas since `tokenAmountsOut` in {RemoveLiquidity} must emit a value
     * for each token in the Well.
     */
    event RemoveLiquidityOneToken(
        uint lpAmountIn,
        IERC20 tokenOut,
        uint tokenAmountOut
    );

    //////////// WELL DEFINITION ////////////
    
    /**
     * @notice Returns a list of ERC20 tokens supported by the Well.
     */
    function tokens() external view returns (IERC20[] memory);

    /**
     * @notice Returns the Well function as a Call struct, which contains the 
     * address of the Well function contract and extra calldata to pass during
     * calls.
     * 
     * **Well functions** define a relationship between the balances of the
     * tokens in the Well and the number of LP tokens.
     * 
     * The Well function should implement {IWellFunction}.
     */
    function wellFunction() external view returns (Call memory);

    /**
     * @notice Returns the Pump attached to the Well as a Call struct, which
     * contains the address of the Pump contract and extra calldata to pass
     * during calls.
     *
     * **Pumps** are on-chain oracles that are updated every time the Well is
     * interacted with.
     *
     * A Pump is not required for Well operation. For Wells without a Pump:
     * `pump().target = address(0)`.
     * 
     * The Pump should implement {IPump}.
     */
    function pump() external view returns (Call memory);

    /**
     * @notice Returns the Tokens, Well function, and Pump associated with
     * this Well.
     */
    function well() external view returns (
        IERC20[] memory _tokens,
        Call memory _wellFunction,
        Call memory _pump
    );

    //////////// SWAP: FROM ////////////

    /**
     * @notice Swaps from an *exact* amount of one token to *at least* an amount
     * of another token.
     * @param fromToken The token to swap from
     * @param toToken The token to swap to
     * @param amountIn The exact amount of `fromToken` to spend
     * @param minAmountOut The minimum amount of `toToken` to receive
     * @param recipient The address to deliver tokens to
     * @return amountOut The amount of `toToken` received
     */
    function swapFrom(
        IERC20 fromToken,
        IERC20 toToken,
        uint amountIn,
        uint minAmountOut,
        address recipient
    ) external returns (uint amountOut);

    /**
     * @notice Calculates the `amountOut` of `toToken` received for `amountIn`
     * of `fromToken` during a swap.
     * @param fromToken The token to swap from
     * @param toToken The token to swap to
     * @param amountIn The exact amount of `fromToken` to spend
     * @return amountOut The amount of `toToken` received
     */
    function getSwapOut(
        IERC20 fromToken,
        IERC20 toToken,
        uint amountIn
    ) external view returns (uint amountOut);

    //////////// SWAP: TO ////////////

    /**
     * @notice Swaps from *at most* an amount of one token to an *exact* amount
     * of another token.
     * @param fromToken The token to swap from
     * @param toToken The token to swap to
     * @param maxAmountIn The maximum amount of `fromToken` to spend
     * @param amountOut The exact amount of `toToken` to receive
     * @param recipient The address to deliver tokens to
     * @return amountIn The amount of `toToken` received
     */
    function swapTo(
        IERC20 fromToken,
        IERC20 toToken,
        uint maxAmountIn,
        uint amountOut,
        address recipient
    ) external returns (uint amountIn);

    /**
     * @notice Calculates the `amountIn` of `fromToken` required to receive `amountOut` of `toToken` during a swap.
     * @param fromToken The token to swap from
     * @param toToken The token to swap to
     * @param amountOut The amount of `toToken` desired
     * @return amountIn The amount of `fromToken` required to receive `amountOut` of `toToken`
     */
    function getSwapIn(
        IERC20 fromToken,
        IERC20 toToken,
        uint amountOut
    ) external view returns (uint amountIn);

    //////////// ADD LIQUIDITY ////////////

    /**
     * @notice Adds liquidity to the Well using any amounts of all tokens
     * @param tokenAmountsIn The exact amounts of tokens to add. The order should match the order of the tokens in the Well
     * @param minLpAmountOut The minimum amount of LP tokens to receive
     * @return lpAmountOut The amount of LP tokens received
     */
    function addLiquidity(
        uint[] memory tokenAmountsIn,
        uint minLpAmountOut,
        address recipient
    ) external returns (uint lpAmountOut);

    /**
     * @notice Calculates the amount of LP tokens to receive from adding liquidity with any amounts of all tokens
     * @param tokenAmountsIn The exact amounts of tokens to add. The order should match the order of the tokens in the Well
     * @return lpAmountOut The amount of LP tokens received from adding liquidity with amounts of all tokens
     */
    function getAddLiquidityOut(uint[] memory tokenAmountsIn)
        external
        view
        returns (uint lpAmountOut);

    //////////// REMOVE LIQUIDITY: BALANCED ////////////

    /**
     * @notice Removes liquidity from the Well in an balanced ratio of all tokens
     * @param lpAmountIn The exact amount of LP tokens to burn
     * @param minTokenAmountsOut The minimum amounts of tokens to receive. The order should match the order of the tokens in the Well
     * @return tokenAmountsOut The amounts of tokens received
     */
    function removeLiquidity(
        uint lpAmountIn,
        uint[] calldata minTokenAmountsOut,
        address recipient
    ) external returns (uint[] memory tokenAmountsOut);

    /**
     * @notice Calculates the amounts of tokens received from removing liquidity in a balanced ratio
     * @param lpAmountIn The exact amount of LP tokens to burn
     * @return tokenAmountsOut The amounts of tokens received from removing liquidity in a balanced ratio
     */
    function getRemoveLiquidityOut(uint lpAmountIn)
        external
        view
        returns (uint[] memory tokenAmountsOut);

    //////////// REMOVE LIQUIDITY: ONE TOKEN ////////////

    /**
     * @notice Removes liquidity from the Well in exchange for one token in the Well
     * @param tokenOut The token to remove liquidity to
     * @param lpAmountIn The exact amount of LP tokens to burn
     * @param minTokenAmountOut The minimum amount of `token` to receive
     * @return tokenAmountOut The amount of `token` received
     */
    function removeLiquidityOneToken(
        uint lpAmountIn,
        IERC20 tokenOut,
        uint minTokenAmountOut,
        address recipient
    ) external returns (uint tokenAmountOut);

    /**
     * @notice Calculates the amount of `token` to receive from removing liquidity in exchange for one token
     * @param token The token to remove liquidity to
     * @param lpAmountIn The exact amount of LP tokens to burn
     * @return tokenAmountOut The amount of `token` received from removing liquidity in exchange for one token
     */
    function getRemoveLiquidityOneTokenOut(
        IERC20 token,
        uint lpAmountIn
    ) external view returns (uint tokenAmountOut);

    //////////// REMOVE LIQUIDITY: IMBALANCED ////////////

    /**
     * @notice Removes liquidity from the Well in any amounts of all tokens
     * @param maxLpAmountIn The maximum amount of LP tokens to burn
     * @param tokenAmountsOut The exact amounts of tokens to receive. The order should match the order of the tokens in the Well
     * @return lpAmountIn The amount of LP tokens burned
     */
    function removeLiquidityImbalanced(
        uint maxLpAmountIn,
        uint[] calldata tokenAmountsOut,
        address recipient
    ) external returns (uint lpAmountIn);

    /**
     * @notice Calculates the amount of LP tokens to burn to remove liquidity in any amounts of all tokens
     * @param tokenAmountsOut The exact amounts of tokens to receive. The order should match the order of the tokens in the Well
     * @return lpAmountIn The amount of LP tokens burned
     */
    function getRemoveLiquidityImbalancedIn(
        uint[] calldata tokenAmountsOut
    ) external view returns (uint lpAmountIn);
}