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
     * address of the Well function contract and extra data to pass during calls.
     * 
     * **Well functions** define a relationship between the balances of the
     * tokens in the Well and the number of LP tokens.
     * 
     * A Well function MUST implement {IWellFunction}.
     */
    function wellFunction() external view returns (Call memory);

    /**
     * @notice Returns the Pump attached to the Well as a Call struct, which
     * contains the address of the Pump contract and extra data to pass during calls.
     *
     * **Pumps** are on-chain oracles that are updated every time the Well is
     * interacted with.
     *
     * A Pump is not required for Well operation. For Wells without a Pump:
     * `pump().target = address(0)`.
     * 
     * An attached Pump MUST implement {IPump}.
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
     * @notice Swaps from an *exact* amount of one token to a *minimum* amount of another token.
     * @param fromToken The token to swap from
     * @param toToken The token to swap to
     * @param amountIn The exact amount of `fromToken` to spend
     * @param minAmountOut The minimum amount of `toToken` to receive
     * @param recipient The address to receive tokens
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
     * @notice Gets the amount of one token received for swapping an amount of another token.
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
     * @notice Swaps from a *maximum* amount of one token to an *exact* amount of another token.
     * @param fromToken The token to swap from
     * @param toToken The token to swap to
     * @param maxAmountIn The maximum amount of `fromToken` to spend
     * @param amountOut The exact amount of `toToken` to receive
     * @param recipient The address to receive tokens
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
     * @notice Gets the amount of one token required to receive an amount of another token during a swap.
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

    //////////// SWAP: UTILITIES ////////////

    /**
     * @notice Gets the output of a swap using the Well's current token balances.
     * @param fromToken The token to swap from
     * @param toToken The token to swap to
     * @param amountIn The Well's change in balance of `fromToken`
     * @return amountOut The Well's change in balance of `toToken`
     * @dev Uses signed integer accounting.
     */
    function getSwap(
        IERC20 fromToken,
        IERC20 toToken,
        int amountIn
    ) external view returns (int amountOut);

    /**
     * @notice Calculates the output of a swap given a list of token balances.
     * @param balances A list of token balances; MUST match the indexing of {Well.tokens}
     * @param i The index of the token to swap from
     * @param j The index of the token to swap to
     * @param amountIn The Well's change in balance of token `i`
     * @return amountOut The Well's change in balance of token `j`
     * @dev Uses signed integer accounting.
     */
    function calculateSwap(
        uint[] memory balances,
        uint i,
        uint j,
        int amountIn
    ) external view returns (int amountOut);

    //////////// ADD LIQUIDITY ////////////

    /**
     * @notice Adds liquidity to the Well using any combination of tokens
     * @param tokenAmountsIn The exact amount of each token to add; MUST match the indexing of {Well.tokens}
     * @param minLpAmountOut The minimum amount of LP tokens to receive
     * @param recipient The address to receive tokens
     * @return lpAmountOut The amount of LP tokens received
     */
    function addLiquidity(
        uint[] memory tokenAmountsIn,
        uint minLpAmountOut,
        address recipient
    ) external returns (uint lpAmountOut);

    /**
     * @notice Calculates the amount of LP tokens to receive from adding liquidity with any combination of tokens
     * @param tokenAmountsIn The exact amount of each token to add; MUST match the indexing of {Well.tokens}
     * @return lpAmountOut The amount of LP tokens received
     */
    function getAddLiquidityOut(uint[] memory tokenAmountsIn)
        external
        view
        returns (uint lpAmountOut);

    //////////// REMOVE LIQUIDITY: BALANCED ////////////

    /**
     * @notice Removes liquidity from the Well in an balanced ratio of all tokens
     * @param lpAmountIn The exact amount of LP tokens to burn
     * @param minTokenAmountsOut The minimum amount of each token to receive; MUST match the indexing of {Well.tokens}
     * @param recipient The address to receive tokens
     * @return tokenAmountsOut The amount of each token received
     */
    function removeLiquidity(
        uint lpAmountIn,
        uint[] calldata minTokenAmountsOut,
        address recipient
    ) external returns (uint[] memory tokenAmountsOut);

    /**
     * @notice Calculates the amount of each token received from removing liquidity in a balanced ratio
     * @param lpAmountIn The amount of LP tokens to burn
     * @return tokenAmountsOut The amount of each token received
     */
    function getRemoveLiquidityOut(uint lpAmountIn)
        external
        view
        returns (uint[] memory tokenAmountsOut);

    //////////// REMOVE LIQUIDITY: ONE TOKEN ////////////

    /**
     * @notice Removes liquidity from the Well as a single token.
     * @param lpAmountIn The amount of LP tokens to burn
     * @param tokenOut The token to remove from the Well
     * @param minTokenAmountOut The minimum amount of `tokenOut` to receive
     * @param recipient The address to receive tokens
     * @return tokenAmountOut The amount of `tokenOut` received
     */
    function removeLiquidityOneToken(
        uint lpAmountIn,
        IERC20 tokenOut,
        uint minTokenAmountOut,
        address recipient
    ) external returns (uint tokenAmountOut);

    /**
     * @notice Calculates the amount received from removing liquidity as a single token
     * @param tokenOut The token to remove from the Well
     * @param lpAmountIn The amount of LP tokens to burn
     * @return tokenAmountOut The amount of `tokenOut` received
     */
    function getRemoveLiquidityOneTokenOut(
        IERC20 tokenOut,
        uint lpAmountIn
    ) external view returns (uint tokenAmountOut);

    //////////// REMOVE LIQUIDITY: IMBALANCED ////////////

    /**
     * @notice Removes liquidity from the Well as a combination of tokens.
     * @param maxLpAmountIn The maximum amount of LP tokens to burn
     * @param tokenAmountsOut The exact amount amount of each token to receive; MUST match the indexing of {Well.tokens}
     * @param recipient The address to receive tokens
     * @return lpAmountIn The amount of LP tokens burned
     */
    function removeLiquidityImbalanced(
        uint maxLpAmountIn,
        uint[] calldata tokenAmountsOut,
        address recipient
    ) external returns (uint lpAmountIn);

    /**
     * @notice Get the amount of LP tokens to burn to remove liquidity in any amounts of all tokens
     * @param tokenAmountsOut The exact amount amount of each token to receive; MUST match the indexing of {Well.tokens}
     * @return lpAmountIn The amount of LP tokens burned
     */
    function getRemoveLiquidityImbalancedIn(
        uint[] calldata tokenAmountsOut
    ) external view returns (uint lpAmountIn);
}