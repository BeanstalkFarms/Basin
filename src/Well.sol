// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ReentrancyGuardUpgradeable} from "ozu/security/ReentrancyGuardUpgradeable.sol";
import {ERC20Upgradeable, ERC20PermitUpgradeable} from "ozu/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import {IERC20, SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "oz/utils/math/SafeCast.sol";
import {IWell, Call} from "src/interfaces/IWell.sol";
import {IPump} from "src/interfaces/pumps/IPump.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {LibBytes} from "src/libraries/LibBytes.sol";
import {ClonePlus} from "src/utils/ClonePlus.sol";

/**
 * @title Well
 * @author Publius, Silo Chad, Brean
 * @dev A Well is a constant function AMM allowing the provisioning of liquidity
 * into a single pooled on-chain liquidity position.
 *
 */
contract Well is ERC20PermitUpgradeable, IWell, ReentrancyGuardUpgradeable, ClonePlus {
    using SafeERC20 for IERC20;
    using SafeCast for uint;

    bytes32 constant RESERVES_STORAGE_SLOT = keccak256("reserves.storage.slot");

    function init(string memory name, string memory symbol) public initializer {
        __ERC20Permit_init(name);
        __ERC20_init(name, symbol);

        Call[] memory _pumps = pumps();
        for (uint i = 0; i < _pumps.length; i++) {
            IPump(_pumps[i].target).attach(numberOfTokens(), new bytes(0));
        }
    }

    //////////////////// WELL DEFINITION ////////////////////

    /// This Well uses a dynamic immutable storage layout. Immutable storage is
    /// used for gas-efficient reads during Well operation. The Well must be
    /// created by cloning with a pre-encoded byte string containing immutable
    /// data. 
    ///
    /// Let n = number of tokens
    ///     m = length of well function data (bytes)
    ///
    /// TYPE        NAME                       LOCATION (CONSTANT)
    /// ==============================================================
    /// address     aquifer()                  0        (LOC_AQUIFER_ADDR)
    /// uint256     numberOfTokens()           20       (LOC_TOKENS_COUNT)
    /// address     wellFunctionAddress()      52       (LOC_WELL_FUNCTION_ADDR)
    /// uint256     wellFunctionDataLength()   72       (LOC_WELL_FUNCTION_DATA_LENGTH)
    /// uint256     numberOfPumps()            104      (LOC_PUMPS_COUNT)
    /// --------------------------------------------------------------
    /// address     token0                     136      (LOC_VARIABLE)
    /// ...
    /// address     tokenN                     136 + (n-1) * 32
    /// --------------------------------------------------------------
    /// byte        wellFunctionData0          136 + n * 32
    /// ...
    /// byte        wellFunctionDataM          136 + n * 32 + m
    /// --------------------------------------------------------------
    /// address     pump1Address               136 + n * 32 + m
    /// uint256     pump1DataLength            136 + n * 32 + m + 20
    /// byte        pump1Data                  136 + n * 32 + m + 52
    /// ...
    /// ==============================================================

    uint constant LOC_AQUIFER_ADDR = 0;
    uint constant LOC_TOKENS_COUNT = LOC_AQUIFER_ADDR + 20;
    uint constant LOC_WELL_FUNCTION_ADDR = LOC_TOKENS_COUNT + 32;
    uint constant LOC_WELL_FUNCTION_DATA_LENGTH = LOC_WELL_FUNCTION_ADDR + 20;
    uint constant LOC_PUMPS_COUNT = LOC_WELL_FUNCTION_DATA_LENGTH + 32;
    uint constant LOC_VARIABLE = LOC_PUMPS_COUNT + 32;

    function tokens() public pure returns (IERC20[] memory ts) {
        ts = _getArgIERC20Array(LOC_VARIABLE, numberOfTokens());
    }

    function wellFunction() public pure returns (Call memory _wellFunction) {
        _wellFunction.target = wellFunctionAddress();
        uint dataLoc = LOC_VARIABLE + numberOfTokens() * 32;
        _wellFunction.data = _getArgBytes(dataLoc, wellFunctionDataLength());
    }

    function pumps() public pure returns (Call[] memory _pumps) {
        if (numberOfPumps() == 0) return _pumps;

        _pumps = new Call[](numberOfPumps());
        uint dataLoc = LOC_VARIABLE + numberOfTokens() * 32 + wellFunctionDataLength();

        uint pumpDataLength;
        for (uint i = 0; i < _pumps.length; i++) {
            _pumps[i].target = _getArgAddress(dataLoc);
            dataLoc += 20;
            pumpDataLength = _getArgUint256(dataLoc);
            dataLoc += 32;
            _pumps[i].data = _getArgBytes(dataLoc, pumpDataLength);
            dataLoc += pumpDataLength;
        }
    }

    function aquifer() public pure override returns (address) {
        return _getArgAddress(LOC_AQUIFER_ADDR);
    }

    function wellData() public pure returns (bytes memory) {}

    function well()
        external
        pure
        returns (
            IERC20[] memory _tokens,
            Call memory _wellFunction,
            Call[] memory _pumps,
            bytes memory _wellData,
            address _aquifer
        )
    {
        _tokens = tokens();
        _wellFunction = wellFunction();
        _pumps = pumps();
        // _wellData = bytes(0); // FIXME
        _aquifer = aquifer();
    }

    //////////////////// WELL DEFINITION: HELPERS ////////////////////

    /**
     * @notice Returns the number of tokens that are tradable in this Well.
     * @dev Length of the `tokens()` array.
     */
    function numberOfTokens() public pure returns (uint) {
        return _getArgUint256(LOC_TOKENS_COUNT);
    }

    /**
     * @notice Returns the address of the Well Function.
     */
    function wellFunctionAddress() public pure returns (address) {
        return _getArgAddress(LOC_WELL_FUNCTION_ADDR);
    }

    /**
     * @notice Returns the length of the configurable `data` parameter passed during calls to the Well Function.
     */
    function wellFunctionDataLength() public pure returns (uint) {
        return _getArgUint256(LOC_WELL_FUNCTION_DATA_LENGTH);
    }

    /**
     * @notice Returns the number of Pumps which this Well was initialized with.
     */
    function numberOfPumps() public pure returns (uint) {
        return _getArgUint256(LOC_PUMPS_COUNT);
    }

    /**
     * @notice Returns address & data used to call the first Pump.
     * @dev Provided as an optimization in the case where {numberOfPumps} returns 1.
     */
    function firstPump() public pure returns (Call memory _pump) {
        uint dataLoc = LOC_VARIABLE + numberOfTokens() * 32 + wellFunctionDataLength();
        _pump.target = _getArgAddress(dataLoc);
        uint pumpDataLength = _getArgUint256(dataLoc + 20);
        _pump.data = _getArgBytes(dataLoc + 52, pumpDataLength);
    }

    //////////////////// SWAP: FROM ////////////////////

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

    function getSwapOut(IERC20 fromToken, IERC20 toToken, uint amountIn) external view returns (uint amountOut) {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _getReserves(_tokens.length);
        (uint i, uint j) = _getIJ(_tokens, fromToken, toToken);

        reserves[i] += amountIn;

        // underflow is desired; Well Function SHOULD NOT increase reserves of both `i` and `j`
        amountOut = reserves[j] - _calcReserve(wellFunction(), reserves, j, totalSupply());
    }

    //////////////////// SWAP: TO ////////////////////

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

        // slippage check needs to move to the actual amount out
        // need to take delta across _executeSwap
        require(amountIn <= maxAmountIn, "Well: slippage");
        _setReserves(reserves);
        _executeSwap(fromToken, toToken, amountIn, amountOut, recipient);
    }

    function getSwapIn(IERC20 fromToken, IERC20 toToken, uint amountOut) external view returns (uint amountIn) {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _getReserves(_tokens.length);
        (uint i, uint j) = _getIJ(_tokens, fromToken, toToken);

        reserves[j] -= amountOut;

        amountIn = _calcReserve(wellFunction(), reserves, i, totalSupply()) - reserves[i];
    }

    //////////////////// SWAP: UTILITIES ////////////////////

    /**
     * @dev Executes token transfers and emits Swap event.
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

    //////////////////// ADD LIQUIDITY ////////////////////

    /**
     * @dev Gas optimization: {IWell.AddLiquidity} is emitted even if `lpAmountOut` is 0.
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
            _tokens[i].safeTransferFrom(msg.sender, address(this), tokenAmountsIn[i]);
            reserves[i] = reserves[i] + tokenAmountsIn[i]; //
        }
        lpAmountOut = _calcLpTokenSupply(wellFunction(), reserves) - totalSupply();

        require(lpAmountOut >= minLpAmountOut, "Well: slippage");
        _mint(recipient, lpAmountOut);
        _setReserves(reserves);
        emit AddLiquidity(tokenAmountsIn, lpAmountOut);
    }

    function getAddLiquidityOut(uint[] memory tokenAmountsIn) external view returns (uint lpAmountOut) {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _getReserves(_tokens.length);
        for (uint i; i < _tokens.length; ++i) {
            reserves[i] = reserves[i] + tokenAmountsIn[i];
        }
        lpAmountOut = _calcLpTokenSupply(wellFunction(), reserves) - totalSupply();
    }

    //////////////////// REMOVE LIQUIDITY: BALANCED ////////////////////

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
            require(tokenAmountsOut[i] >= minTokenAmountsOut[i], "Well: slippage");
            _tokens[i].safeTransfer(recipient, tokenAmountsOut[i]);
            reserves[i] = reserves[i] - tokenAmountsOut[i];
        }

        _setReserves(reserves);
        emit RemoveLiquidity(lpAmountIn, tokenAmountsOut);
    }

    function getRemoveLiquidityOut(uint lpAmountIn) external view returns (uint[] memory tokenAmountsOut) {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _getReserves(_tokens.length);
        uint lpTokenSupply = totalSupply();

        tokenAmountsOut = new uint[](_tokens.length);
        for (uint i; i < _tokens.length; ++i) {
            tokenAmountsOut[i] = (lpAmountIn * reserves[i]) / lpTokenSupply;
        }
    }

    //////////////////// REMOVE LIQUIDITY: ONE TOKEN ////////////////////

    function removeLiquidityOneToken(
        uint lpAmountIn,
        IERC20 tokenOut,
        uint minTokenAmountOut,
        address recipient
    ) external nonReentrant returns (uint tokenAmountOut) {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _updatePumps(_tokens.length);
        uint j = _getJ(_tokens, tokenOut);

        tokenAmountOut = _getRemoveLiquidityOneTokenOut(lpAmountIn, j, reserves);
        require(tokenAmountOut >= minTokenAmountOut, "Well: slippage");
        _burn(msg.sender, lpAmountIn);
        tokenOut.safeTransfer(recipient, tokenAmountOut);

        reserves[j] = reserves[j] - tokenAmountOut;
        _setReserves(reserves);
        emit RemoveLiquidityOneToken(lpAmountIn, tokenOut, tokenAmountOut);
    }

    function getRemoveLiquidityOneTokenOut(
        uint lpAmountIn,
        IERC20 tokenOut
    ) external view returns (uint tokenAmountOut) {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _getReserves(_tokens.length);
        uint j = _getJ(_tokens, tokenOut);
        tokenAmountOut = _getRemoveLiquidityOneTokenOut(lpAmountIn, j, reserves);
    }

    /**
     * @dev Shared logic for removing a single token from liquidity.
     * Calculates change in reserve `j` given a change in LP token supply.
     *
     * Note: `lpAmountIn` is the amount of LP the user is burning in exchange
     * for some amount of token `j`.
     */
    function _getRemoveLiquidityOneTokenOut(
        uint lpAmountIn,
        uint j,
        uint[] memory reserves
    ) private view returns (uint tokenAmountOut) {
        uint newLpTokenSupply = totalSupply() - lpAmountIn;
        uint newReserveJ = _calcReserve(wellFunction(), reserves, j, newLpTokenSupply);
        tokenAmountOut = reserves[j] - newReserveJ;
    }

    //////////// REMOVE LIQUIDITY: IMBALANCED ////////////

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

    function getRemoveLiquidityImbalancedIn(uint[] calldata tokenAmountsOut) external view returns (uint lpAmountIn) {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _getReserves(_tokens.length);
        for (uint i; i < _tokens.length; ++i) {
            reserves[i] = reserves[i] - tokenAmountsOut[i];
        }
        lpAmountIn = totalSupply() - _calcLpTokenSupply(wellFunction(), reserves);
    }

    //////////////////// SKIM ////////////////////

    function skim(address recipient) external nonReentrant returns (uint[] memory skimAmounts) {
        IERC20[] memory _tokens = tokens();
        uint[] memory reserves = _getReserves(_tokens.length);
        skimAmounts = new uint[](_tokens.length);
        for (uint i; i < _tokens.length; ++i) {
            skimAmounts[i] = _tokens[i].balanceOf(address(this)) - reserves[i];
            if (skimAmounts[i] > 0) {
                _tokens[i].safeTransfer(recipient, skimAmounts[i]);
            }
        }
    }

    //////////////////// UPDATE PUMP ////////////////////

    /**
     * @dev Fetches the current token reserves of the Well and updates the Pumps.
     * Typically called before an operation that modifies the Well's reserves.
     */
    function _updatePumps(uint _numberOfTokens) internal returns (uint[] memory reserves) {
        reserves = _getReserves(_numberOfTokens);

        if (numberOfPumps() == 0) {
            return reserves;
        }

        // gas optimization: avoid looping if there is only one pump
        if (numberOfPumps() == 1) {
            Call memory _pump = firstPump();
            IPump(_pump.target).update(reserves, _pump.data);
        } else {
            Call[] memory _pumps = pumps();
            for (uint i; i < _pumps.length; ++i) {
                IPump(_pumps[i].target).update(reserves, _pumps[i].data);
            }
        }
    }

    //////////////////// GET & SET RESERVES ////////////////////

    function getReserves() external view returns (uint[] memory reserves) {
        reserves = _getReserves(numberOfTokens());
    }

    /**
     * @dev Gets the Well's token reserves by reading from byte storage.
     */
    function _getReserves(uint _numberOfTokens) internal view returns (uint[] memory reserves) {
        reserves = LibBytes.readUint128(RESERVES_STORAGE_SLOT, _numberOfTokens);
    }

    /**
     * @dev Sets the Well's reserves of each token by writing to byte storage.
     */
    function _setReserves(uint[] memory reserves) internal {
        LibBytes.storeUint128(RESERVES_STORAGE_SLOT, reserves);
    }

    //////////////////// WELL FUNCTION INTERACTION ////////////////////

    /**
     * @dev Calculates the LP token supply given a list of `reserves` from the provided
     * `_wellFunction`. Wraps {IWellFunction.calcLpTokenSupply}.
     *
     * The Well function is passed as a parameter to minimize gas in instances
     * where it is called multiple times in one transaction.
     */
    function _calcLpTokenSupply(
        Call memory _wellFunction,
        uint[] memory reserves
    ) internal view returns (uint lpTokenSupply) {
        lpTokenSupply = IWellFunction(_wellFunction.target).calcLpTokenSupply(reserves, _wellFunction.data);
    }

    /**
     * @dev Calculates the `j`th reserve given a list of `reserves` and `lpTokenSupply`
     * from the provided `_wellFunction`. Wraps {IWellFunction.calcReserve}.
     *
     * The Well function is passed as a parameter to minimize gas in instances
     * where it is called multiple times in one transaction.
     */
    function _calcReserve(
        Call memory _wellFunction,
        uint[] memory reserves,
        uint j,
        uint lpTokenSupply
    ) internal view returns (uint reserve) {
        reserve = IWellFunction(_wellFunction.target).calcReserve(reserves, j, lpTokenSupply, _wellFunction.data);
    }

    //////////////////// WELL TOKEN INDEXING ////////////////////

    /**
     * @dev Returns the indices of `iToken` and `jToken` in `_tokens`. Reverts if either token is not in `_tokens`.
     */
    function _getIJ(IERC20[] memory _tokens, IERC20 iToken, IERC20 jToken) internal pure returns (uint i, uint j) {
        bool foundI = false;
        bool foundJ = false;

        for (uint k; k < _tokens.length; ++k) {
            if (iToken == _tokens[k]) {
                i = k;
                foundI = true;
            } else if (jToken == _tokens[k]) {
                j = k;
                foundJ = true;
            }
        }

        require(foundI && foundJ, "Well: Invalid tokens");
    }

    /**
     * @dev Returns the index of `jToken` in `_tokens`. Reverts if `jToken` is not in `_tokens`.
     */
    function _getJ(IERC20[] memory _tokens, IERC20 jToken) internal pure returns (uint j) {
        for (j; j < _tokens.length; ++j) {
            if (jToken == _tokens[j]) {
                return j;
            }
        }
        revert("Well: Invalid tokens");
    }
}
