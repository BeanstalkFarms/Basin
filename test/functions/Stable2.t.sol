// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {console, TestHelper, IERC20} from "test/TestHelper.sol";
import {WellFunctionHelper, IMultiFlowPumpWellFunction} from "./WellFunctionHelper.sol";
import {Stable2} from "src/functions/Stable2.sol";
import {Stable2LUT1} from "src/functions/StableLUT/Stable2LUT1.sol";

/// @dev Tests the {Stable2} Well function directly.
contract Stable2Test is WellFunctionHelper {
    /**
     * State A: Same decimals
     * D (lpTokenSupply) should be the summation of
     * the reserves, assuming they are equal.
     */
    uint256 STATE_A_B0 = 10 * 1e18;
    uint256 STATE_A_B1 = 10 * 1e18;
    uint256 STATE_A_LP = 20 * 1e18;

    /**
     * State B: Different decimals
     * @notice the stableswap implmentation
     * uses precision-adjusted to 18 decimals.
     * In other words, a token with 6 decimals
     * will be scaled up such that it uses 18 decimals.
     *
     * @dev D is the summation of the reserves,
     * assuming they are equal.
     *
     */
    uint256 STATE_B_B0 = 10 * 1e18;
    uint256 STATE_B_B1 = 20 * 1e6;
    uint256 STATE_B_LP = 29_405_570_361_996_060_057; // ~29.4e18

    /// State C: Similar decimals
    uint256 STATE_C_B0 = 20 * 1e12;
    uint256 STATE_C_B1 = 25 * 1e18;
    uint256 STATE_C_LP = 44_906_735_116_816_626_495; // 44.9e18

    /// @dev See {calcLpTokenSupply}.
    uint256 MAX_RESERVE = 1e32;

    //////////// SETUP ////////////

    function setUp() public {
        IERC20[] memory _tokens = deployMockTokens(2);
        tokens = _tokens;
        address lut = address(new Stable2LUT1());
        _function = IMultiFlowPumpWellFunction(new Stable2(lut));
    }

    function test_metadata() public view {
        assertEq(_function.name(), "Stable2");
        assertEq(_function.symbol(), "S2");
    }

    //////////// LP TOKEN SUPPLY ////////////

    /// @dev calcLpTokenSupply: same decimals, manual calc for 2 equal reserves
    function test_calcLpTokenSupply_sameDecimals() public view {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = STATE_A_B0;
        reserves[1] = STATE_A_B1;
        assertEq(
            _function.calcLpTokenSupply(reserves, new bytes(0)),
            STATE_A_LP // sqrt(10e18 * 10e18) * 2
        );
    }

    /// @dev calcLpTokenSupply: diff decimals
    function test_calcLpTokenSupply_diffDecimals() public view {
        uint256[] memory reserves = new uint256[](2);
        uint256[] memory data = new uint256[](2);
        data[0] = 18;
        data[1] = 6;
        reserves[0] = STATE_B_B0; // 10 USDT
        reserves[1] = STATE_B_B1; // 20 BEAN
        assertEq(_function.calcLpTokenSupply(reserves, abi.encode(data)), STATE_B_LP);
    }

    //////////// RESERVES ////////////

    /// @dev calcReserve: same decimals, both positions
    /// Matches example in {testLpTokenSupplySameDecimals}.
    function test_calcReserve_sameDecimals() public view {
        uint256[] memory reserves = new uint256[](2);

        /// STATE A
        // find reserves[0]
        reserves[0] = 0;
        reserves[1] = STATE_A_B1;
        assertEq(_function.calcReserve(reserves, 0, STATE_A_LP, new bytes(0)), STATE_A_B0);

        // find reserves[1]
        reserves[0] = STATE_A_B0;
        reserves[1] = 0;
        assertEq(_function.calcReserve(reserves, 1, STATE_A_LP, new bytes(0)), STATE_A_B1);

        /// STATE C
        // find reserves[1]
        uint256[] memory data = new uint256[](2);
        data[0] = 12;
        data[1] = 18;
        reserves[0] = STATE_C_B0;
        reserves[1] = 0;
        assertEq(_function.calcReserve(reserves, 1, STATE_C_LP, abi.encode(data)), STATE_C_B1);
    }

    /// @dev calcReserve: diff decimals, both positions
    /// Matches example in {testLpTokenSupplyDiffDecimals}.
    function test_calcReserve_diffDecimals() public view {
        uint256[] memory data = new uint256[](2);
        data[0] = 18;
        data[1] = 6;
        uint256[] memory reserves = new uint256[](2);

        /// STATE B
        // find reserves[0]
        reserves[0] = 0;
        reserves[1] = STATE_B_B1;
        assertEq(
            _function.calcReserve(reserves, 0, STATE_B_LP, abi.encode(data)),
            STATE_B_B0 // (70710678118654 / 2)^2 / 1250e6 = ~1e18
        );

        // find reserves[1]
        reserves[0] = STATE_B_B0; // placeholder
        reserves[1] = 0; // ex. 1250 BEAN
        assertEq(
            _function.calcReserve(reserves, 1, STATE_B_LP, abi.encode(data)),
            STATE_B_B1 // (70710678118654 / 2)^2 / 1e18 = 1250e6
        );
    }

    //////////// LP TOKEN SUPPLY ////////////

    /// @dev invariant: reserves -> lpTokenSupply -> reserves should match
    function testFuzz_calcLpTokenSupply(uint256[2] memory _reserves) public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = bound(_reserves[0], 10e18, MAX_RESERVE);
        reserves[1] = bound(_reserves[1], 10e18, MAX_RESERVE);

        uint256 lpTokenSupply = _function.calcLpTokenSupply(reserves, new bytes(0));
        uint256[] memory underlying =
            _function.calcLPTokenUnderlying(lpTokenSupply, reserves, lpTokenSupply, new bytes(0));
        for (uint256 i = 0; i < reserves.length; ++i) {
            assertEq(reserves[i], underlying[i], "reserves mismatch");
        }
    }

    //////////// FUZZ ////////////

    function testFuzz_stableSwap(uint256 x, uint256 y, uint256 a) public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = bound(x, 10e18, MAX_RESERVE);
        reserves[1] = bound(y, 10e18, MAX_RESERVE);
        a = bound(a, 1, 1_000_000);

        uint256 lpTokenSupply = _function.calcLpTokenSupply(reserves, new bytes(0));
        uint256 reserve0 = _function.calcReserve(reserves, 0, lpTokenSupply, new bytes(0));
        uint256 reserve1 = _function.calcReserve(reserves, 1, lpTokenSupply, new bytes(0));

        if (reserves[0] < 1e12) {
            assertApproxEqAbs(reserve0, reserves[0], 1);
        } else {
            assertApproxEqRel(reserve0, reserves[0], 3e6);
        }
        if (reserves[1] < 1e12) {
            assertApproxEqAbs(reserve1, reserves[1], 1);
        } else {
            assertApproxEqRel(reserve1, reserves[1], 3e6);
        }
    }

    ///////// CALC RATE ///////

    function test_calcRateStable() public view {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 1e18;
        reserves[1] = 1e18;
        assertEq(_function.calcRate(reserves, 0, 1, new bytes(0)), 1e6);
        assertEq(_function.calcRate(reserves, 1, 0, new bytes(0)), 1e6);
    }

    function test_calcRateStable6Decimals() public {
        uint256[] memory data = new uint256[](2);
        data[0] = 18;
        data[1] = 6;
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 100e18;
        reserves[1] = 100e6;
        assertEq(_function.calcRate(reserves, 1, 0, abi.encode(data)), 1e6);
        assertEq(_function.calcRate(reserves, 0, 1, abi.encode(data)), 1e6);
    }
}
