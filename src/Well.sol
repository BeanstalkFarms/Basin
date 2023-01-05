/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "ozu/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "ozu/proxy/utils/Initializable.sol";
import "ozu/utils/math/SafeCastUpgradeable.sol";

import "src/interfaces/IWell.sol";
import "src/interfaces/IPump.sol";
import "src/interfaces/IWellFunction.sol";

import "src/libraries/LibWellUtilities.sol";
import "src/libraries/LibContractInfo.sol";

/**
 * @author Publius
 * @title Well
 * @dev
 * A Well serves as an constant function AMM allowing the provisioning of liquidity into a single pooled on-chain liquidity position.
 * Each Well has tokens, a pricing function, and pumps stored in a WellInfo struct.
 * - tokens defines the set of tokens that can be exchanged in the pool.
 * - The pricing function defines an invariant relationship between the balances of the tokens in the pool and the number of LP tokens. See {IWellFunction}
 * - pumps are on-chain oracles that are updated every time the pool is interacted with. See {IPump}.
 * Users can swap tokens in and add/remove liquidity to a Well.
 *
 * Implementation of ERC-20, ERC-2612 and {IWell} interface.
 * 
 * WellInfo is a parameter of all function calls.
 * The input WellInfo is verified to be the same as the WellInfo used to initialize the Well by comparing hashes.
 * This requires less SLOADs than reading WellInfo from storage.
 **/

contract Well is ERC20PermitUpgradeable, IWell {

    /// @dev wellHash contains the hash of the WellInfo struct used to initialize the Well.
    /// It is used to verify that the WellInfo struct passed to a function is the same as the one used to initialize the Well.
    bytes32 public wellHash;

    /// @dev wi contains the WellInfo struct used to initialize the Well. See {WellInfo}.
    WellInfo wi;

    using LibContractInfo for address;
    using SafeCastUpgradeable for uint256;

    /// @dev see {IWell.initialize}
    function initialize(WellInfo calldata w) external initializer {
        wi.wellFunction = w.wellFunction;
        wi.tokens = w.tokens;
        for (uint256 i = 0; i < w.pumps.length; i++) {
            IPump(w.pumps[i].target).initialize(
                w.pumps[i].data,
                w.tokens.length
            );
            wi.pumps.push(w.pumps[i]);
        }
        wellHash = LibWellUtilities.computeWellHash(w);
        initNameAndSymbol(w);
    }

    /// @dev see {IWell.wellInfo}
    function wellInfo() external view returns (WellInfo memory) {
        return wi;
    }

    /// @dev see {IWell.tokens}
    function tokens() external view returns (IERC20[] memory) {
        return wi.tokens;
    }

    /// @dev see {IWell.pumps}
    function pumps() external view returns (Call[] memory) {
        return wi.pumps;
    }

    /// @dev see {IWell.wellFunction}
    function wellFunction() external view returns (Call memory) {
        return wi.wellFunction;
    }

    /// @dev see {IWell.decimals}
    /// The number of decimals is set to the average of the decimals of the tokens in the well.
    function decimals() public view override returns (uint8) {
        uint256 totalDecimals;
        for (uint256 i = 0; i < wi.tokens.length; i++) {
            totalDecimals += address(wi.tokens[i]).getDecimals();
        }
        return (totalDecimals / wi.tokens.length).toUint8();
    }

    /**
     * Swap
     **/

    /// @dev see {IWell.swapFrom}
    function swapFrom(
        WellInfo calldata w,
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient
    ) external verifyInfo(w) returns (uint256 amountOut) {
        amountOut = uint256(
            updatePumpsAndgetSwap(w, fromToken, toToken, int256(amountIn), int256(minAmountOut))
        );
        _executeSwap(fromToken, toToken, amountIn, amountOut, recipient);
    }

    /// @dev see {IWell.swapTo}
    function swapTo(
        WellInfo calldata w,
        IERC20 fromToken,
        IERC20 toToken,
        uint256 maxAmountIn,
        uint256 amountOut,
        address recipient
    ) external verifyInfo(w) returns (uint256 amountIn) {
        amountIn = uint256(
            -updatePumpsAndgetSwap(
                w,
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
        WellInfo calldata w,
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amountOut
    ) external view returns (uint256 amountIn) {
        amountIn = uint256(-getSwap(w, toToken, fromToken, -int256(amountOut)));
    }

    /// @dev see {IWell.getSwapOut}
    function getSwapOut(
        WellInfo calldata w,
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amountIn
    ) external view returns (uint256 amountOut) {
        amountOut = uint256(getSwap(w, fromToken, toToken, int256(amountIn)));
    }

    /// @dev low level swap function. Fetches balances, indexes of tokens and returns swap output.
    /// given a change in balance of iToken, returns change in balance of jToken.
    function getSwap(
        WellInfo calldata w,
        IERC20 iToken,
        IERC20 jToken,
        int256 dXi
    ) public view returns (int256 dXj) {
        uint256[] memory balances = getBalances(w.tokens);
        (uint256 i, uint256 j) = getIJ(w.tokens, iToken, jToken);
        dXj = calculateSwap(w.wellFunction, balances, i, j, dXi);
    }

    /// @dev same as {getSwap}, but also updates pumps
    function updatePumpsAndgetSwap(
        WellInfo calldata w,
        IERC20 iToken,
        IERC20 jToken,
        int256 dXi,
        int256 minDx_j
    ) internal returns (int256 dXj) {
        uint256[] memory balances = getBalancesAndUpdatePumps(
            w.tokens,
            w.pumps
        );
        (uint256 i, uint256 j) = getIJ(w.tokens, iToken, jToken);
        dXj = calculateSwap(w.wellFunction, balances, i, j, dXi);
        require(dXj >= minDx_j, "Well: slippage");
    }

    /// @dev contains core swap logic. 
    /// A swap to a specified amount is the same as a swap from a negative specified amount.
    /// Thus, swapFrom and swapTo can use the same swap logic using signed math.
    function calculateSwap(
        Call calldata _wellFunction,
        uint256[] memory xs,
        uint256 i,
        uint256 j,
        int256 dXi
    ) public view returns (int256 dXj) {
        uint256 d = getD(_wellFunction, xs);
        xs[i] = dXi > 0 ? xs[i] + uint256(dXi) : xs[i] - uint256(-dXi);
        dXj = int256(xs[j]) - int256(getXj(_wellFunction, xs, j, d));
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
        WellInfo calldata w,
        uint256[] memory tokenAmountsIn,
        uint256 minAmountOut,
        address recipient
    ) external verifyInfo(w) returns (uint256 amountOut) {
        uint256[] memory balances = getBalancesAndUpdatePumps(
            w.tokens,
            w.pumps
        );
        for (uint256 i; i < w.tokens.length; ++i) {
            w.tokens[i].transferFrom(
                msg.sender,
                address(this),
                tokenAmountsIn[i]
            );
            balances[i] = balances[i] + tokenAmountsIn[i];
        }
        amountOut = getD(w.wellFunction, balances) - totalSupply();
        require(amountOut >= minAmountOut, "Well: slippage");
        _mint(recipient, amountOut);
        emit AddLiquidity(tokenAmountsIn, amountOut);
    }

    /// @dev see {IWell.getAddLiquidityOut}
    function getAddLiquidityOut(
        WellInfo calldata w,
        uint256[] memory tokenAmountsIn
    ) external view returns (uint256 amountOut) {
        uint256[] memory balances = getBalances(w.tokens);
        for (uint256 i; i < w.tokens.length; ++i)
            balances[i] = balances[i] + tokenAmountsIn[i];
        amountOut = getD(w.wellFunction, balances) - totalSupply();
    }

    /**
     * Remove Liquidity
     **/

    /// @dev see {IWell.removeLiquidity}
    function removeLiquidity(
        WellInfo calldata w,
        uint256 lpAmountIn,
        uint256[] calldata minTokenAmountsOut,
        address recipient
    ) external verifyInfo(w) returns (uint256[] memory tokenAmountsOut) {
        uint256[] memory balances = getBalancesAndUpdatePumps(
            w.tokens,
            w.pumps
        );
        uint256 d = totalSupply();
        tokenAmountsOut = new uint256[](w.tokens.length);
        _burn(msg.sender, lpAmountIn);
        for (uint256 i; i < w.tokens.length; ++i) {
            tokenAmountsOut[i] = (lpAmountIn * balances[i]) / d;
            require(
                tokenAmountsOut[i] >= minTokenAmountsOut[i],
                "Well: slippage"
            );
            w.tokens[i].transfer(recipient, tokenAmountsOut[i]);
        }
        emit RemoveLiquidity(lpAmountIn, tokenAmountsOut);
    }

    /// @dev see {IWell.getRemoveLiquidityOut}
    function getRemoveLiquidityOut(WellInfo calldata w, uint256 lpAmountIn)
        external
        view
        returns (uint256[] memory tokenAmountsOut)
    {
        uint256[] memory balances = getBalances(w.tokens);
        uint256 d = totalSupply();
        tokenAmountsOut = new uint256[](w.tokens.length);
        for (uint256 i; i < w.tokens.length; ++i) {
            tokenAmountsOut[i] = (lpAmountIn * balances[i]) / d;
        }
    }

    /**
     * Remove Liquidity One Token
     **/

    /// @dev see {IWell.removeLiquidityOneToken}
    function removeLiquidityOneToken(
        WellInfo calldata w,
        IERC20 token,
        uint256 lpAmountIn,
        uint256 minTokenAmountOut,
        address recipient
    ) external verifyInfo(w) returns (uint256 tokenAmountOut) {
        uint256[] memory balances = getBalancesAndUpdatePumps(
            w.tokens,
            w.pumps
        );
        tokenAmountOut = _getRemoveLiquidityOneTokenOut(
            w,
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
    function getRemoveLiquidityOneTokenOut(
        WellInfo calldata w,
        IERC20 token,
        uint256 lpAmountIn
    ) external view returns (uint256 tokenAmountOut) {
        uint256[] memory balances = getBalances(w.tokens);
        tokenAmountOut = _getRemoveLiquidityOneTokenOut(
            w,
            token,
            balances,
            lpAmountIn
        );
    }

    function _getRemoveLiquidityOneTokenOut(
        WellInfo calldata w,
        IERC20 token,
        uint256[] memory balances,
        uint256 lpAmountIn
    ) private view returns (uint256 tokenAmountOut) {
        uint256 j = getJ(w.tokens, token);
        uint256 newD = totalSupply() - lpAmountIn;
        uint256 newXj = getXj(w.wellFunction, balances, j, newD);
        tokenAmountOut = balances[j] - newXj;
    }

    /**
     * Remove Liquidity Imbalanced
     **/

    /// @dev see {IWell.removeLiquidityImbalanced}
    function removeLiquidityImbalanced(
        WellInfo calldata w,
        uint256 maxLPAmountIn,
        uint256[] calldata tokenAmountsOut,
        address recipient
    ) external verifyInfo(w) returns (uint256 lpAmountIn) {
        uint256[] memory balances = getBalancesAndUpdatePumps(
            w.tokens,
            w.pumps
        );
        lpAmountIn = _getRemoveLiquidityImbalanced(
            w,
            balances,
            tokenAmountsOut
        );
        require(lpAmountIn <= maxLPAmountIn, "Well: slippage");
        _burn(msg.sender, lpAmountIn);
        for (uint256 i; i < w.tokens.length; ++i)
            w.tokens[i].transfer(recipient, tokenAmountsOut[i]);
        emit RemoveLiquidity(lpAmountIn, tokenAmountsOut);
    }

    /// @dev see {IWell.getRemoveLiquidityImbalanced}
    function getRemoveLiquidityImbalanced(
        WellInfo calldata w,
        uint256[] calldata tokenAmountsOut
    ) external view returns (uint256 lpAmountIn) {
        uint256[] memory balances = getBalances(w.tokens);
        lpAmountIn = _getRemoveLiquidityImbalanced(
            w,
            balances,
            tokenAmountsOut
        );
    }

    function _getRemoveLiquidityImbalanced(
        WellInfo calldata w,
        uint256[] memory balances,
        uint256[] calldata tokenAmountsOut
    ) private view returns (uint256) {
        for (uint256 i; i < w.tokens.length; ++i)
            balances[i] = balances[i] - tokenAmountsOut[i];
        return totalSupply() - getD(w.wellFunction, balances);
    }

    /// @dev returns the balances of the well and updates the pumps
    function getBalancesAndUpdatePumps(
        IERC20[] calldata _tokens,
        Call[] calldata _pumps
    ) internal returns (uint256[] memory balances) {
        balances = getBalances(_tokens);
        updatePumps(_pumps, balances);
    }

    /// @dev updates the pumps with the previous balances
    function updatePumps(Call[] calldata pump, uint256[] memory balances)
        internal
    {
        for (uint256 i; i < pump.length; ++i)
            IPump(pump[i].target).update(pump[i].data, balances);
    }

    /// @dev returns the balances of the tokens by calling balanceOf on each token
    function getBalances(IERC20[] calldata _tokens)
        internal
        view
        returns (uint256[] memory balances)
    {
        balances = new uint256[](_tokens.length);
        for (uint256 i; i < _tokens.length; ++i)
            balances[i] = _tokens[i].balanceOf(address(this));
    }

    /// @dev returns the d value given the xs.
    /// wraps the getD function in the well function contract
    function getD(Call calldata _wellFunction, uint256[] memory xs)
        internal
        view
        returns (uint256 d)
    {
        d = IWellFunction(_wellFunction.target).getD(_wellFunction.data, xs);
    }

    /// @dev returns the x value at index i given d and the other xs.
    /// wraps the getXj function in the well function contract
    function getXj(
        Call calldata wf,
        uint256[] memory xs,
        uint256 j,
        uint256 d
    ) internal view returns (uint256 x) {
        x = IWellFunction(wf.target).getXj(wf.data, xs, j, d);
    }

    /// @dev returns the index of fromToken and toToken in tokens
    function getIJ(
        IERC20[] calldata _tokens,
        IERC20 iToken,
        IERC20 jToken
    ) internal pure returns (uint256 i, uint256 j) {
        for (uint256 k; k < _tokens.length; ++k) {
            if (iToken == _tokens[i]) i = k;
            else if (jToken == _tokens[i]) j = k;
        }
    }

    /// @dev returns the index of token in tokens
    function getJ(IERC20[] calldata _tokens, IERC20 iToken)
        internal
        pure
        returns (uint256 i)
    {
        for (uint256 k; k < _tokens.length; ++k)
            if (iToken == _tokens[i]) return k;
    }

    /// @dev verifies that w is the correct WellInfo by comparing the hash to the stored Well hash.
    /// Every function that modifies the Well balances should have this modifier.
    modifier verifyInfo(WellInfo calldata w) {
        bytes32 wh = LibWellUtilities.computeWellHash(w);
        require(wh == wellHash, "LibWell: wrong well hash.");
        _;
    }

    /// @dev sets the name and symbol of the Well
    /// name is in format `<token0Symbol>:...:<tokenNSymbol> <wellFunctionName> Well`
    /// symbol is in format `<token0Symbol>...<tokenNSymbol><wellFunctionSymbol>w`
    function initNameAndSymbol(WellInfo calldata w)
        internal
        returns (string memory name, string memory symbol)
    {
        name = address(w.tokens[0]).getSymbol();
        symbol = name;
        for (uint256 i = 1; i < w.tokens.length; ++i) {
            name = string.concat(name, ":", address(w.tokens[i]).getSymbol());
            symbol = string.concat(symbol, address(w.tokens[i]).getSymbol());
        }
        name = string.concat(
            name,
            " ",
            w.wellFunction.target.getName(),
            " Well"
        );
        symbol = string.concat(symbol, w.wellFunction.target.getSymbol(), "w");
        __ERC20_init(name, symbol);
    }
}
