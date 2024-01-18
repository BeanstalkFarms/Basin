// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TestHelper, console} from "test/TestHelper.sol";
import {Call, IERC20} from "src/interfaces/IWell.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";
import {MultiFlowPump, ABDKMathQuad} from "src/pumps/MultiFlowPump.sol";
import {simCapReserve50Percent, from18, to18} from "test/pumps/PumpHelpers.sol";
import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";
import {MockStaticWell} from "mocks/wells/MockStaticWell.sol";
import {ReentrancyGuardUpgradeable} from "ozu/security/ReentrancyGuardUpgradeable.sol";
import {Math} from "oz/utils/math/Math.sol";

contract CapBalanceTest is TestHelper, MultiFlowPump {
    using ABDKMathQuad for bytes16;

    using Math for uint256;

    uint256[] lastReserves;
    uint256[] reserves;
    bytes16[][] maxRatioChanges;
    bytes16 maxLpSupplyIncrease;
    bytes16 maxLpSupplyDecrease;
    bytes16 capExponent;

    // uint256 MAX_RESERVE = 1e32;
    uint256 MAX_RESERVE = 1e24;

    address _well;

    ConstantProduct2 public wf;

    constructor()
        MultiFlowPump()
    {
        lastReserves = new uint256[](2);
        reserves = new uint256[](2);

        maxLpSupplyIncrease = from18(0.05e18);
        maxLpSupplyDecrease = from18(0.04761904762e18);

        maxRatioChanges = new bytes16[][](2);
        maxRatioChanges[0] = new bytes16[](2);
        maxRatioChanges[1] = new bytes16[](2);
        maxRatioChanges[0][1] = from18(0.05e18);
        maxRatioChanges[1][0] = from18(0.05e18);

        wf = new ConstantProduct2();

        _well = address(new MockStaticWell(
            deployMockTokens(2),
            Call(address(wf), new bytes(0)),
            deployPumps(1),
            address(0),
            new bytes(0)
        ));
    }

    function test_capReserve_belowCap() public {
        lastReserves[0] = 100;
        lastReserves[1] = 100;

        reserves[0] = 101;
        reserves[1] = 102;

        uint256[] memory cappedReserves = _capReserves(
            address(_well),
            lastReserves,
            reserves,
            1, // capExponent
            CapReservesParameters(
                maxRatioChanges,
                maxLpSupplyIncrease,
                maxLpSupplyDecrease
            )
        );
        
        assertEq(cappedReserves[0], 101);
        assertEq(cappedReserves[1], 102);
    }

    function test_capReserve_aboveRatioCap() public {
        lastReserves[0] = 1000;
        lastReserves[1] = 1000;

        reserves[0] = 980;
        reserves[1] = 1031;

        uint256[] memory cappedReserves = _capReserves(
            address(_well),
            lastReserves,
            reserves,
            1, // capExponent
            MultiFlowPump.CapReservesParameters(
                maxRatioChanges,
                maxLpSupplyIncrease,
                maxLpSupplyDecrease
            )
        );

        assertEq(cappedReserves[0], 980);
        assertEq(cappedReserves[1], 1029);
    }

    function test_capReserve_belowRatioCap() public {
        lastReserves[0] = 1000;
        lastReserves[1] = 1000;

        reserves[0] = 979;
        reserves[1] = 1029;

        uint256[] memory cappedReserves = _capReserves(
            address(_well),
            lastReserves,
            reserves,
            1, // capExponent
            MultiFlowPump.CapReservesParameters(
                maxRatioChanges,
                maxLpSupplyIncrease,
                maxLpSupplyDecrease
            )
        );

        assertEq(cappedReserves[0], 979);
        assertEq(cappedReserves[1], 1028);
    }

    function testFuzz_capReserve_oneBlock(
        uint256[2] memory _lastReserves,
        uint256[2] memory _reserves
    ) public {
        lastReserves = new uint256[](2);
        lastReserves[0] = bound(_lastReserves[0], 1e6, MAX_RESERVE);
        lastReserves[1] = bound(
            _lastReserves[1],
            Math.max(1e6, lastReserves[0] / MultiFlowPump.CAP_PRECISION * 10),
            Math.min(MAX_RESERVE, lastReserves[0] * MultiFlowPump.CAP_PRECISION / 10)
        );

        reserves = new uint256[](2);
        reserves[0] = bound(_reserves[0], 1e6, MAX_RESERVE);
        reserves[1] = bound(
            _reserves[1],
            Math.max(1e6, reserves[0] / MultiFlowPump.CAP_PRECISION),
            Math.min(MAX_RESERVE, reserves[0] * MultiFlowPump.CAP_PRECISION)
        );

        uint256[] memory cappedReserves = _capReserves(
            address(_well),
            lastReserves,
            reserves,
            1, // capExponent
            MultiFlowPump.CapReservesParameters(
                maxRatioChanges,
                maxLpSupplyIncrease,
                maxLpSupplyDecrease
            )
        );

        uint256 precision = numDigits(cappedReserves[0])
            .min(numDigits(cappedReserves[1]))
            .min(numDigits(reserves[0]))
            .min(numDigits(reserves[1]));
        if (precision >= 3) precision = precision - 3;
        else precision = 1;
        console.log("Digit precision: %s", precision);
        uint256 absolutePrecision = 100;

        uint256 lpTokenSupplyBefore = wf.calcLpTokenSupply(lastReserves, new bytes(0));
        uint256 maxLpTokenSupply = lpTokenSupplyBefore * (1e18 + to18(maxLpSupplyIncrease)) / 1e18;
        uint256 minLpTokenSupply = lpTokenSupplyBefore * (1e18 - to18(maxLpSupplyDecrease)) / 1e18;
        uint256 lpTokenSupplyCapped = wf.calcLpTokenSupply(cappedReserves, new bytes(0));
        console.log("LP Token Supply Before: %s", lpTokenSupplyBefore);
        console.log("LP Token Supply Max: %s", maxLpTokenSupply);
        console.log("LP Token Supply Capped: %s", lpTokenSupplyCapped);
        console.log("LP Token Supply Min: %s", minLpTokenSupply);

        precision = precision.min(numDigits(lpTokenSupplyCapped) - 2).min(numDigits(lpTokenSupplyCapped.sqrt()) - 2);
        console.log("LP Token Supply Digits: %s", precision);
        // console.log("Sqrt: %s", numDigits(lpTokenSupplyCapped.sqrt()));
        // console.log("Capped Supply Digits: %s", numDigits(lpTokenSupplyCapped) - 5);

        assertApproxGeRelN(lpTokenSupplyCapped, minLpTokenSupply, precision, absolutePrecision);
        assertApproxLeRelN(lpTokenSupplyCapped, maxLpTokenSupply, precision, absolutePrecision);

        assertNotEq(cappedReserves[0], 0);
        assertNotEq(cappedReserves[1], 0);

        if (cappedReserves[0] == 1) return;
        if (cappedReserves[1] == 1) return;

        (uint256 i, uint256 j) = lastReserves[0] > lastReserves[1] ? (0, 1) : (1, 0);

        uint256 rIJMax = lastReserves[i] * (1e18 + to18(maxRatioChanges[i][j])) / lastReserves[j];
        uint256 rIJMin = lastReserves[i] * 1e18 / (1 + to18(maxRatioChanges[i][j])) / lastReserves[j];
        uint256 rIJCapped = cappedReserves[i] * 1e18 / cappedReserves[j];
        console.log("Max R: %s", rIJMax);
        console.log("Min R: %s", rIJMin);
        console.log("Output R: %s", rIJCapped);
        console.log("Checking Max!");
        assertApproxLeRelN(rIJCapped, rIJMax, precision, absolutePrecision);
        console.log("Checking Min!");
        assertApproxGeRelN(rIJCapped, rIJMin, precision, absolutePrecision);
    }
}
