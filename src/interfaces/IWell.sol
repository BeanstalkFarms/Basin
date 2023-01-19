/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "oz/token/ERC20/IERC20.sol";

/**
 * @title Call is the struct that contains the target address and extra calldata of a generic call.
 */
struct Call {
    address target; // The address the call is executed on.
    bytes data; // Extra calldata to be passed during the call
}

/**
 * @title IWell is the interface for the Well contract.
 */
interface IWell {

    /**
     * @notice Emitted when a Swap occurs.
     * @param fromToken The token swapped from
     * @param toToken The token swapped to
     * @param amountIn The amount of `fromToken` transferred into the Well
     * @param amountOut The amount of `toToken` transferred out of the Well
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
     * @notice Emitted when liquidity is removed from the Well as multiple underlying tokens.
     * @param lpAmountIn The amount of LP tokens burned
     * @param tokenAmountsOut The amount of each underlying token removed
     * @dev Gas cost scales with `n` tokens.
     */
    event RemoveLiquidity(
        uint lpAmountIn,
        uint[] tokenAmountsOut
    );
    
    /**
     * @notice Emitted when liquidity is removed from the Well as a single underlying token.
     * @param lpAmountIn The amount of LP tokens burned
     * @param tokenOut The underlying token removed
     * @param tokenAmountOut The amount of `tokenOut` removed
     * @dev Emitting a separate event when removing liquidity as a single token
     * saves gas, since `tokenAmountsOut` in {RemoveLiquidity} must emit a value
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
     * @notice Returns the Well function as a Call struct.
     * @dev Contains the address of the Well function contract and extra data to 
     * pass during calls.
     * 
     * **Well functions** define a relationship between the balances of the
     * tokens in the Well and the number of LP tokens.
     * 
     * A Well function MUST implement {IWellFunction}.
     */
    function wellFunction() external view returns (Call memory);

    /**
     * @notice Returns the Pumps attached to the Well as Call structs.
     * @dev Contains the addresses of the Pumps contract and extra data to pass
     * during calls.
     *
     * **Pumps** are on-chain oracles that are updated every time the Well is
     * interacted with.
     *
     * A Pump is not required for Well operation. For Wells without a Pump:
     * `pumps().length = 0`.
     * 
     * An attached Pump MUST implement {IPump}.
     */
    function pumps() external view returns (Call[] memory);

    /**
     * @notice Returns the Auger that bore this Well.
     * @dev Contains the address of the Auger contract.
     * 
     * The Auger determines the Well's implementation. Different Augers can be
     * implemented to deploy Wells with implementations that optimize for
     * different use cases.
     * 
     * Only Wells deployed by a verified Auger should be considered legitimate.
     * 
     */
    function auger() external view returns (address);

    /**
     * @notice Returns the tokens, Well function, and Pump associated with this Well.
     */
    function well() external view returns (
        IERC20[] memory _tokens,
        Call memory _wellFunction,
        Call[] memory _pumps,
        address _auger
    );

    //////////// SWAP: FROM ////////////

    /**
     * @notice Swaps from an exact amount of `fromToken` to a minimum amount of `toToken`.
     * @param fromToken The token to swap from
     * @param toToken The token to swap to
     * @param amountIn The amount of `fromToken` to spend
     * @param minAmountOut The minimum amount of `toToken` to receive
     * @param recipient The address to receive `toToken`
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
     * @param amountIn The amount of `fromToken` to spend
     * @return amountOut The amount of `toToken` to receive
     */
    function getSwapOut(
        IERC20 fromToken,
        IERC20 toToken,
        uint amountIn
    ) external view returns (uint amountOut);

    //////////// SWAP: TO ////////////

    /**
     * @notice Swaps from a maximum amount of `fromToken` to an exact amount of `toToken`.
     * @param fromToken The token to swap from
     * @param toToken The token to swap to
     * @param maxAmountIn The maximum amount of `fromToken` to spend
     * @param amountOut The amount of `toToken` to receive
     * @param recipient The address to receive `toToken`
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
     * @notice Gets the amount of one token that must be spent to receive an amount of another token during a swap.
     * @param fromToken The token to swap from
     * @param toToken The token to swap to
     * @param amountOut The amount of `toToken` desired
     * @return amountIn The amount of `fromToken` that must be spent
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

    //////////// ADD LIQUIDITY ////////////

    /**
     * @notice Adds liquidity to the Well as multiple tokens in any ratio.
     * @param tokenAmountsIn The amount of each token to add; MUST match the indexing of {Well.tokens}
     * @param minLpAmountOut The minimum amount of LP tokens to receive
     * @param recipient The address to receive the LP tokens
     * @return lpAmountOut The amount of LP tokens received
     */
    function addLiquidity(
        uint[] memory tokenAmountsIn,
        uint minLpAmountOut,
        address recipient
    ) external returns (uint lpAmountOut);

    /**
     * @notice Gets the amount of LP tokens received from adding liquidity as multiple tokens in any ratio.
     * @param tokenAmountsIn The amount of each token to add; MUST match the indexing of {Well.tokens}
     * @return lpAmountOut The amount of LP tokens to receive
     */
    function getAddLiquidityOut(uint[] memory tokenAmountsIn)
        external
        view
        returns (uint lpAmountOut);

    //////////// REMOVE LIQUIDITY: BALANCED ////////////

    /**
     * @notice Removes liquidity from the Well as all underlying tokens in a balanced ratio.
     * @param lpAmountIn The amount of LP tokens to burn
     * @param minTokenAmountsOut The minimum amount of each underlying token to receive; MUST match the indexing of {Well.tokens}
     * @param recipient The address to receive the underlying tokens
     * @return tokenAmountsOut The amount of each underlying token received
     */
    function removeLiquidity(
        uint lpAmountIn,
        uint[] calldata minTokenAmountsOut,
        address recipient
    ) external returns (uint[] memory tokenAmountsOut);

    /**
     * @notice Gets the amount of each underlying token received from removing liquidity in a balanced ratio.
     * @param lpAmountIn The amount of LP tokens to burn
     * @return tokenAmountsOut The amount of each underlying token to receive
     */
    function getRemoveLiquidityOut(uint lpAmountIn)
        external
        view
        returns (uint[] memory tokenAmountsOut);

    //////////// REMOVE LIQUIDITY: ONE TOKEN ////////////

    /**
     * @notice Removes liquidity from the Well as a single underlying token.
     * @param lpAmountIn The amount of LP tokens to burn
     * @param tokenOut The underlying token to receive
     * @param minTokenAmountOut The minimum amount of `tokenOut` to receive
     * @param recipient The address to receive the underlying tokens
     * @return tokenAmountOut The amount of `tokenOut` received
     */
    function removeLiquidityOneToken(
        uint lpAmountIn,
        IERC20 tokenOut,
        uint minTokenAmountOut,
        address recipient
    ) external returns (uint tokenAmountOut);

    /**
     * @notice Gets the amount received from removing liquidity from the Well as a single underlying token.
     * @param tokenOut The underlying token to receive
     * @param lpAmountIn The amount of LP tokens to burn
     * @return tokenAmountOut The amount of `tokenOut` to receive
     *
     * FIXME: ordering
     */
    function getRemoveLiquidityOneTokenOut(
        IERC20 tokenOut,
        uint lpAmountIn
    ) external view returns (uint tokenAmountOut);

    //////////// REMOVE LIQUIDITY: IMBALANCED ////////////

    /**
     * @notice Removes liquidity from the Well as multiple underlying tokens in any ratio.
     * @param maxLpAmountIn The maximum amount of LP tokens to burn
     * @param tokenAmountsOut The amount of each underlying token to receive; MUST match the indexing of {Well.tokens}
     * @param recipient The address to receive the underlying tokens
     * @return lpAmountIn The amount of LP tokens burned
     */
    function removeLiquidityImbalanced(
        uint maxLpAmountIn,
        uint[] calldata tokenAmountsOut,
        address recipient
    ) external returns (uint lpAmountIn);

    /**
     * @notice Gets the amount of LP tokens to burn from removing liquidity as multiple underlying tokens in any ratio.
     * @param tokenAmountsOut The amount of each underlying token to receive; MUST match the indexing of {Well.tokens}
     * @return lpAmountIn The amount of LP tokens to burn
     */
    function getRemoveLiquidityImbalancedIn(
        uint[] calldata tokenAmountsOut
    ) external view returns (uint lpAmountIn);
}