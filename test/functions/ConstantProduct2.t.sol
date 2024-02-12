// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IWellFunction, TestHelper} from "test/TestHelper.sol";
import {WellFunctionHelper} from "./WellFunctionHelper.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";

/// @dev Tests the {ConstantProduct2} Well function directly.
contract ConstantProduct2Test is WellFunctionHelper {
    /// State A: Same decimals
    uint256 STATE_A_B0 = 10 * 1e18;
    uint256 STATE_A_B1 = 10 * 1e18;
    uint256 STATE_A_LP = 10 * 1e24;

    /// State B: Different decimals
    uint256 STATE_B_B0 = 1 * 1e18;
    uint256 STATE_B_B1 = 1250 * 1e6;
    uint256 STATE_B_LP = 35_355_339_059_327_376_220;

    /// State C: Similar decimals
    uint256 STATE_C_B0 = 20 * 1e18;
    uint256 STATE_C_B1 = 31_250_000_000_000_000_000; // 3.125e19
    uint256 STATE_C_LP = 25 * 1e24;

    /// @dev See {calcLpTokenSupply}.
    uint256 MAX_RESERVE = 1e32;

    //////////// SETUP ////////////

    function setUp() public {
        _function = new ConstantProduct2();
        _data = "";
    }

    function test_metadata() public {
        assertEq(_function.name(), "Constant Product 2");
        assertEq(_function.symbol(), "CP2");
    }

    //////////// LP TOKEN SUPPLY ////////////

    /// @dev reverts when trying to calculate lp token supply with < 2 reserves
    function test_calcLpTokenSupply_minBalancesLength() public {
        check_calcLpTokenSupply_minBalancesLength(2);
    }

    /// @dev calcLpTokenSupply: same decimals, manual calc for 2 equal reserves
    function test_calcLpTokenSupply_sameDecimals() public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = STATE_A_B0;
        reserves[1] = STATE_A_B1;
        assertEq(
            _function.calcLpTokenSupply(reserves, _data),
            STATE_A_LP // sqrt(10e18 * 10e18) * 2
        );
    }

    /// @dev calcLpTokenSupply: diff decimals
    function test_calcLpTokenSupply_diffDecimals() public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = STATE_B_B0; // ex. 1 WETH
        reserves[1] = STATE_B_B1; // ex. 1250 BEAN
        assertEq(
            _function.calcLpTokenSupply(reserves, _data),
            STATE_B_LP // sqrt(1e18 * 1250e6) * 2
        );
    }

    //////////// RESERVES ////////////

    /// @dev calcReserve: same decimals, both positions
    /// Matches example in {testLpTokenSupplySameDecimals}.
    function test_calcReserve_sameDecimals() public {
        uint256[] memory reserves = new uint256[](2);

        /// STATE A
        // find reserves[0]
        reserves[0] = 0;
        reserves[1] = STATE_A_B1;
        assertEq(
            _function.calcReserve(reserves, 0, STATE_A_LP, _data),
            STATE_A_B0 // (20e18/2) ^ 2 / 10e18 = 10e18
        );

        // find reserves[1]
        reserves[0] = STATE_A_B0;
        reserves[1] = 0;
        assertEq(_function.calcReserve(reserves, 1, STATE_A_LP, _data), STATE_A_B1);

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
        uint256[] memory reserves = new uint256[](2);

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
    function testFuzz_calcLpTokenSupply(uint256[2] memory _reserves) public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = bound(_reserves[0], 1, MAX_RESERVE);
        reserves[1] = bound(_reserves[1], 1, MAX_RESERVE);
        uint256 lpTokenSupply = _function.calcLpTokenSupply(reserves, _data);
        uint256[] memory underlying = _function.calcLPTokenUnderlying(lpTokenSupply, reserves, lpTokenSupply, "");
        for (uint256 i; i < reserves.length; ++i) {
            assertEq(reserves[i], underlying[i], "reserves mismatch");
        }
    }

    //////////// FUZZ ////////////

    function testFuzz_constantProduct2(uint256 x, uint256 y) public {
        uint256[] memory reserves = new uint256[](2);
        bytes memory _data = new bytes(0);

        reserves[0] = bound(x, 1, MAX_RESERVE);
        reserves[1] = bound(y, 1, MAX_RESERVE);

        uint256 lpTokenSupply = _function.calcLpTokenSupply(reserves, _data);
        uint256 reserve0 = _function.calcReserve(reserves, 0, lpTokenSupply, _data);
        uint256 reserve1 = _function.calcReserve(reserves, 1, lpTokenSupply, _data);

        if (reserves[0] < 1e12) {
            assertApproxEqAbs(reserve0, reserves[0], 2);
        } else {
            assertApproxEqRel(reserve0, reserves[0], 3e6);
        }
        if (reserves[1] < 1e12) {
            assertApproxEqAbs(reserve1, reserves[1], 2);
        } else {
            assertApproxEqRel(reserve1, reserves[1], 3e6);
        }
    }

    function test_calcReserve_invalidJ() public {
        uint256[] memory reserves = new uint256[](2);
        vm.expectRevert(IWellFunction.InvalidJArgument.selector);
        _function.calcReserve(reserves, 2, 1e18, _data);
    }

    function test_calcRate() public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 100;
        reserves[1] = 1;
        assertEq(_function.calcRate(reserves, 0, 1, _data), 100e18);
        assertEq(_function.calcRate(reserves, 1, 0, _data), 0.01e18);
    }

    function test_fuzz_calcRate(uint256[2] memory _reserves) public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = bound(_reserves[0], 1, MAX_RESERVE);
        reserves[1] = bound(_reserves[1], 1, MAX_RESERVE);
        assertEq(_function.calcRate(reserves, 0, 1, _data), reserves[0] * 1e18 / reserves[1]);

        assertEq(_function.calcRate(reserves, 1, 0, _data), reserves[1] * 1e18 / reserves[0]);
    }
}
