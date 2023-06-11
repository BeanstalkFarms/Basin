// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {console, TestHelper} from "test/TestHelper.sol";
import {WellFunctionHelper} from "./WellFunctionHelper.sol";
import {StableSwap} from "src/functions/StableSwap.sol";

/// @dev Tests the {StableSwap} Well function directly.
contract StableSwapTest is WellFunctionHelper {
    /**
     * State A: Same decimals
     * D (lpTokenSupply) should be the summation of 
     * the reserves, assuming they are equal.
     */ 
    uint STATE_A_B0 = 10 * 1e18;
    uint STATE_A_B1 = 10 * 1e18;
    uint STATE_A_LP = 20 * 1e18;

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
    uint STATE_B_B0 = 10 * 1e18;
    uint STATE_B_B1 = 20 * 1e18;
    uint STATE_B_LP = 29_911_483_643_966_454_823; // ~29e18
    

    /// State C: Similar decimals
    uint STATE_C_B0 = 20 * 1e18;
    uint STATE_C_LP = 25 * 1e24;
    uint STATE_C_B1 = 2_221_929_790_566_403_172_822_276_028; // 2.221e19

    /// @dev See {calcLpTokenSupply}.
    uint MAX_RESERVE = 6e31;

    //////////// SETUP ////////////

    function setUp() public {
        _function = new StableSwap(10);
        _data = "";
    }

    function test_metadata() public {
        assertEq(_function.name(), "StableSwap");
        assertEq(_function.symbol(), "SS");
    }

    //////////// LP TOKEN SUPPLY ////////////

    /// @dev reverts when trying to calculate lp token supply with < 2 reserves
    function test_calcLpTokenSupply_minBalancesLength() public {
        check_calcLpTokenSupply_minBalancesLength(2);
    }

    /// @dev calcLpTokenSupply: same decimals, manual calc for 2 equal reserves
    function test_calcLpTokenSupply_sameDecimals() public {
        uint[] memory reserves = new uint[](2);
        reserves[0] = STATE_A_B0;
        reserves[1] = STATE_A_B1;
        assertEq(
            _function.calcLpTokenSupply(reserves, _data),
            STATE_A_LP // sqrt(10e18 * 10e18) * 2
        );
    }

    /// @dev calcLpTokenSupply: diff decimals
    function test_calcLpTokenSupply_diffDecimals() public {
        uint[] memory reserves = new uint[](2);
        reserves[0] = STATE_B_B0; // ex. 1 WETH
        reserves[1] = STATE_B_B1; // ex. 1250 BEAN
        assertEq(
            _function.calcLpTokenSupply(reserves, _data),
            STATE_B_LP
        );
    }

    //////////// RESERVES ////////////

    /// @dev calcReserve: same decimals, both positions
    /// Matches example in {testLpTokenSupplySameDecimals}.
    function test_calcReserve_sameDecimals() public {
        uint[] memory reserves = new uint[](2);

        /// STATE A
        // find reserves[0]
        reserves[0] = 0;
        reserves[1] = STATE_A_B1;
        assertEq(
            _function.calcReserve(reserves, 0, STATE_A_LP, _data),
            STATE_A_B0 
        );

        // find reserves[1]
        reserves[0] = STATE_A_B0;
        reserves[1] = 0;
        assertEq(
            _function.calcReserve(reserves, 1, STATE_A_LP, _data), 
            STATE_A_B1
        );

        /// STATE C
        // find reserves[1]
        reserves[0] = STATE_C_B0;
        reserves[1] = 0;
        assertEq(
            _function.calcReserve(reserves, 1, STATE_C_LP, _data),
            STATE_C_B1 // (50e18/2) ^ 2 / 20e18 = 31.25e19
        );
    }

    /// @dev calcReserve: diff decimals, both positions
    /// Matches example in {testLpTokenSupplyDiffDecimals}.
    function test_calcReserve_diffDecimals() public {
        uint[] memory reserves = new uint[](2);

        /// STATE B
        // find reserves[0]
        reserves[0] = 0;
        reserves[1] = STATE_B_B1;
        assertEq(
            _function.calcReserve(reserves, 0, STATE_B_LP, _data),
            STATE_B_B0 // (70710678118654 / 2)^2 / 1250e6 = ~1e18
        );

        // find reserves[1]
        reserves[0] = STATE_B_B0; // placeholder
        reserves[1] = 0; // ex. 1250 BEAN
        assertEq(
            _function.calcReserve(reserves, 1, STATE_B_LP, _data),
            STATE_B_B1 // (70710678118654 / 2)^2 / 1e18 = 1250e6
        );
    }

    //////////// LP TOKEN SUPPLY ////////////

    /// @dev invariant: reserves -> lpTokenSupply -> reserves should match
    function testFuzz_calcLpTokenSupply(uint[2] memory _reserves) public {
        uint[] memory reserves = new uint[](2);
        reserves[0] = bound(_reserves[0], 1e18, MAX_RESERVE);
        reserves[1] = bound(_reserves[1], 1e18, MAX_RESERVE);
        uint lpTokenSupply = _function.calcLpTokenSupply(reserves, _data);
        console.log("lpTokenSupply: ", lpTokenSupply);
        uint[] memory underlying = _function.calcLPTokenUnderlying(lpTokenSupply, reserves, lpTokenSupply, "");
        console.log("underlying1: ", underlying[0]);
        console.log("underlying0: ", underlying[1]);
        for (uint i = 0; i < reserves.length; ++i) {
            assertEq(reserves[i], underlying[i], "reserves mismatch");
        }
    }

    //////////// FUZZ ////////////

    function testFuzz_constantProduct2(uint x, uint y) public {
        uint[] memory reserves = new uint[](2);
        bytes memory _data = new bytes(0);

        reserves[0] = bound(x, 1e18, MAX_RESERVE);
        reserves[1] = bound(y, 1e18, MAX_RESERVE);

        uint lpTokenSupply = _function.calcLpTokenSupply(reserves, _data);
        uint reserve0 = _function.calcReserve(reserves, 0, lpTokenSupply, _data);
        uint reserve1 = _function.calcReserve(reserves, 1, lpTokenSupply, _data);

        if (reserves[0] < 1e12) {
            assertApproxEqAbs(reserve0, reserves[0], 1);
            // assertApproxEqRel(reserve0, reserves[0], 3e6);
            console.log("check1");
        } else {
            assertApproxEqRel(reserve0, reserves[0], 3e6);
            console.log("check2");
        }
        if (reserves[1] < 1e12) {
            assertApproxEqAbs(reserve1, reserves[1], 1);
            // assertApproxEqRel(reserve0, reserves[0], 3e6);
            console.log("check3");
        } else {
            assertApproxEqRel(reserve1, reserves[1], 3e6);
            console.log("check4");
        }
    }
}
