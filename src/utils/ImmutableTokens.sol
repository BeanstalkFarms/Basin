/**
 * SPDX-License-Identifier: MIT
 *
 */

pragma solidity ^0.8.17;

import {IERC20} from "oz/token/ERC20/IERC20.sol";

/**
 * @title ImmutableTokens provides immutable storage for a list of up to MAX_TOKENS tokens.
 */
contract ImmutableTokens {
    uint private constant MAX_TOKENS = 4;
    IERC20 private constant NULL_TOKEN = IERC20(address(0));

    uint private immutable _numberOfTokens;
    IERC20 private immutable _token0;
    IERC20 private immutable _token1;
    IERC20 private immutable _token2;
    IERC20 private immutable _token3;
    // IERC20 private immutable _token4;
    // IERC20 private immutable _token5;
    // IERC20 private immutable _token6;
    // IERC20 private immutable _token7;
    // IERC20 private immutable _token8;
    // IERC20 private immutable _token9;
    // IERC20 private immutable _token10;
    // IERC20 private immutable _token11;
    // IERC20 private immutable _token12;
    // IERC20 private immutable _token13;
    // IERC20 private immutable _token14;
    // IERC20 private immutable _token15;

    /**
     * @dev During {Well} construction, the tokens array is copied into
     * immutable storage slots for gas efficiency.
     */
    constructor(IERC20[] memory _tokens) {
        require(_tokens.length <= MAX_TOKENS, "Too many tokens");
        _numberOfTokens = _tokens.length;
        _token0 = getTokenFromList(0, _tokens);
        _token1 = getTokenFromList(1, _tokens);
        _token2 = getTokenFromList(2, _tokens);
        _token3 = getTokenFromList(3, _tokens);
        // _token4 = getTokenFromList(4, _tokens);
        // _token5 = getTokenFromList(5, _tokens);
        // _token6 = getTokenFromList(6, _tokens);
        // _token7 = getTokenFromList(7, _tokens);
        // _token8 = getTokenFromList(8, _tokens);
        // _token9 = getTokenFromList(9, _tokens);
        // _token10 = getTokenFromList(10, _tokens);
        // _token11 = getTokenFromList(11, _tokens);
        // _token12 = getTokenFromList(12, _tokens);
        // _token13 = getTokenFromList(13, _tokens);
        // _token14 = getTokenFromList(14, _tokens);
        // _token15 = getTokenFromList(15, _tokens);
    }

    /**
     * @dev Return the number of tokens held in immutable storage.
     */
    function numberOfTokens() public view virtual returns (uint __numberOfTokens) {
        __numberOfTokens = _numberOfTokens;
    }

    /**
     * @dev Reconstruct tokens array from immutable storage slots & immutable length.
     */
    function tokens() public view virtual returns (IERC20[] memory _tokens) {
        _tokens = new IERC20[](_numberOfTokens);
        if (_numberOfTokens == 0) return _tokens;
        _tokens[0] = _token0;
        if (_numberOfTokens == 1) return _tokens;
        _tokens[1] = _token1;
        if (_numberOfTokens == 2) return _tokens;
        _tokens[2] = _token2;
        if (_numberOfTokens == 3) return _tokens;
        _tokens[3] = _token3;
        if (_numberOfTokens == 4) return _tokens;
        // _tokens[4] = _token4;
        // if (_numberOfTokens == 5) return _tokens;
        // _tokens[5] = _token5;
        // if (_numberOfTokens == 6) return _tokens;
        // _tokens[6] = _token6;
        // if (_numberOfTokens == 7) return _tokens;
        // _tokens[7] = _token7;
        // if (_numberOfTokens == 8) return _tokens;
        // _tokens[8] = _token8;
        // if (_numberOfTokens == 9) return _tokens;
        // _tokens[9] = _token9;
        // if (_numberOfTokens == 10) return _tokens;
        // _tokens[10] = _token10;
        // if (_numberOfTokens == 11) return _tokens;
        // _tokens[11] = _token11;
        // if (_numberOfTokens == 12) return _tokens;
        // _tokens[12] = _token12;
        // if (_numberOfTokens == 13) return _tokens;
        // _tokens[13] = _token13;
        // if (_numberOfTokens == 14) return _tokens;
        // _tokens[14] = _token14;
        // if (_numberOfTokens == 15) return _tokens;
        // _tokens[15] = _token15;
    }

    /**
     * @dev Find the immutable storage slot corresponding to token `i`.
     */
    function token(uint i) public view virtual returns (IERC20 _token) {
        if (i == 0) _token = _token0;
        else if (i == 1) _token = _token1;
        else if (i == 2) _token = _token2;
        else if (i == 3) _token = _token3;
        // else if (i == 4) _token = _token4;
        // else if (i == 5) _token = _token5;
        // else if (i == 6) _token = _token6;
        // else if (i == 7) _token = _token7;
        // else if (i == 8) _token = _token8;
        // else if (i == 9) _token = _token9;
        // else if (i == 10) _token = _token10;
        // else if (i == 11) _token = _token11;
        // else if (i == 12) _token = _token12;
        // else if (i == 13) _token = _token13;
        // else if (i == 14) _token = _token14;
        // else if (i == 15) _token = _token15;
    }

    /**
     * @dev Attempt to fetch a token `i` from `_tokens`, returning `NULL_TOKEN`
     * if not present. Used during {ImmutableTokens} construction.
     */
    function getTokenFromList(uint i, IERC20[] memory _tokens) private pure returns (IERC20 _token) {
        if (i >= _tokens.length) _token = NULL_TOKEN;
        else _token = _tokens[i];
    }
}
