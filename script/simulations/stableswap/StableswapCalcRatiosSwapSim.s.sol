// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Stable2} from "src/functions/Stable2.sol";
import {Stable2LUT1} from "src/functions/StableLUT/Stable2LUT1.sol";

/**
 * Stable2 well function simulation and precalculations used
 * to produce the token ratios for the lookup table needed for the initial
 * `calcReserveAtRatioSwap` estimates.
 */
contract StableswapCalcRatiosSwapSim is Script {
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
        bytes memory data = abi.encode(18, 18);
        // calculateLP token supply (this remains unchanged)
        uint256 lpTokenSupply = stable2.calcLpTokenSupply(reserves, data);
        console.log("lp_token_supply: %d", lpTokenSupply);
        uint256 reserve_x = init_reserve_x;
        uint256 price;

        // for n times (1...n) :
        // 1) increment x_n-1 by some amount to get x_n
        // 2) calc y_n using calcReserves(...)
        // 3) calc price_n using calcRate(...)

        // csv header
        console.log("Price (P),Reserve (x),Reserve (y)");

        for (uint256 i; i < 20; i++) {
            // update reserve x
            reserve_x = reserve_x * 92 / 100;
            reserves[0] = reserve_x;
            // get y_n --> corresponding reserve y for a given liquidity level
            uint256 reserve_y = stable2.calcReserve(reserves, 1, lpTokenSupply, data);
            // update reserve y
            reserves[1] = reserve_y;
            // mark price
            price = stable2.calcRate(reserves, 0, 1, data);
            console.log("%d,%d,%d", price, reserve_x, reserve_y);
        }

        // reset reserves
        reserve_x = init_reserve_x;

        for (uint256 i; i < 40; i++) {
            // update reserve x
            reserve_x = reserve_x * 99 / 100;
            reserves[0] = reserve_x;
            // get y_n --> corresponding reserve y for a given liquidity level
            uint256 reserve_y = stable2.calcReserve(reserves, 1, lpTokenSupply, data);
            // update reserve y
            reserves[1] = reserve_y;
            // mark price
            price = stable2.calcRate(reserves, 0, 1, data);
            console.log("%d,%d,%d", price, reserve_x, reserve_y);
        }

        // reset reserves
        reserve_x = init_reserve_x;

        for (uint256 i; i < 40; i++) {
            // update reserve x
            reserve_x = reserve_x * 101 / 100;
            reserves[0] = reserve_x;
            // get y_n --> corresponding reserve y for a given liquidity level
            uint256 reserve_y = stable2.calcReserve(reserves, 1, lpTokenSupply, data);
            // update reserve y
            reserves[1] = reserve_y;
            // mark price
            price = stable2.calcRate(reserves, 0, 1, data);
            console.log("%d,%d,%d", price, reserve_x, reserve_y);
        }

        // reset reserves
        reserve_x = init_reserve_x;

        for (uint256 i; i < 18; i++) {
            // update reserve x
            reserve_x = reserve_x * 105 / 100;
            reserves[0] = reserve_x;
            // get y_n --> corresponding reserve y for a given liquidity level
            uint256 reserve_y = stable2.calcReserve(reserves, 1, lpTokenSupply, data);
            // update reserve y
            reserves[1] = reserve_y;
            // mark price
            price = stable2.calcRate(reserves, 0, 1, data);
            console.log("%d,%d,%d", price, reserve_x, reserve_y);
        }

        // Extreme prices

        // extreme low
        reserve_x = init_reserve_x * 3;
        reserves[0] = reserve_x;
        uint256 reserve_y = stable2.calcReserve(reserves, 1, lpTokenSupply, data);
        reserves[1] = reserve_y;
        price = stable2.calcRate(reserves, 0, 1, data);
        console.log("%d,%d,%d", price, reserve_x, reserve_y);

        // extreme high
        reserve_x = init_reserve_x * 1 / 190;
        reserves[0] = reserve_x;
        reserve_y = stable2.calcReserve(reserves, 1, lpTokenSupply, data);
        reserves[1] = reserve_y;
        price = stable2.calcRate(reserves, 0, 1, data);
        console.log("%d,%d,%d", price, reserve_x, reserve_y);
    }
}
