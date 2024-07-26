// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Stable2} from "src/functions/Stable2.sol";
import {Stable2LUT1} from "src/functions/StableLUT/Stable2LUT1.sol";

/**
 * Stable2 well function simulation and precalculations used
 * to produce the token ratios for the lookup table needed for the initial
 * `calcReserveAtRatioLiquidity` estimates.
 */
contract StableswapCalcRatiosLiqSim is Script {
    function run() external {
        Stable2LUT1 stable2LUT1 = new Stable2LUT1();
        Stable2 stable2 = new Stable2(address(stable2LUT1));
        console.log("stable2.getAParameter(): %d", stable2LUT1.getAParameter());
        // initial reserves
        uint256 init_reserve_x = 1_000_000e18;
        uint256 init_reserve_y = 1_000_000e18;
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = init_reserve_x;
        reserves[1] = init_reserve_y;
        uint256 reserve_y = init_reserve_y;
        bytes memory data = abi.encode(18, 18);
        uint256 price;

        // for n times (1...n) :
        // 1) modify reserve x_n-1 by some percentage (this changes the pool liquidity)
        // 3) calc price_n using calcRate(...)

        // csv header
        console.log("Price (P),Reserve (x),Reserve (y)");

        // calcReserveAtRatioLiquidity
        for (uint256 i; i < 20; i++) {
            // update reserves
            reserve_y = reserve_y * 88 / 100;
            reserves[1] = reserve_y;
            // mark price
            price = stable2.calcRate(reserves, 0, 1, data);
            console.log("%d,%d,%d", price, init_reserve_x, reserve_y);
        }

        // reset reserves
        reserve_y = init_reserve_y;

        // calcReserveAtRatioLiquidity
        for (uint256 i; i < 20; i++) {
            // update reserves
            reserve_y = reserve_y * 98 / 100;
            reserves[1] = reserve_y;
            // mark price
            price = stable2.calcRate(reserves, 0, 1, data);
            console.log("%d,%d,%d", price, init_reserve_x, reserve_y);
        }

        // reset reserves
        reserve_y = init_reserve_y;

        // calcReserveAtRatioLiquidity
        for (uint256 i; i < 20; i++) {
            // update reserves
            reserve_y = reserve_y * 102 / 100;
            reserves[1] = reserve_y;
            // mark price
            price = stable2.calcRate(reserves, 0, 1, data);
            console.log("%d,%d,%d", price, init_reserve_x, reserve_y);
        }

        // reset reserves
        reserve_y = init_reserve_y;

        // calcReserveAtRatioLiquidity
        for (uint256 i; i < 20; i++) {
            // update reserves
            reserve_y = reserve_y * 112 / 100;
            reserves[1] = reserve_y;
            // mark price
            price = stable2.calcRate(reserves, 0, 1, data);
            console.log("%d,%d,%d", price, init_reserve_x, reserve_y);
        }

        // Extreme prices

        // extreme low
        reserve_y = init_reserve_y * 1 / 28;
        reserves[1] = reserve_y;
        price = stable2.calcRate(reserves, 0, 1, data);
        console.log("%d,%d,%d", price, init_reserve_x, reserve_y);

        // extreme high
        reserve_y = init_reserve_y * 2000;
        reserves[1] = reserve_y;
        price = stable2.calcRate(reserves, 0, 1, data);
        console.log("%d,%d,%d", price, init_reserve_x, reserve_y);
    }
}
