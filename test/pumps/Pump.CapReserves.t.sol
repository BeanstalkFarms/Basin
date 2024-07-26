// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TestHelper, console} from "test/TestHelper.sol";
import {Call, IERC20} from "src/interfaces/IWell.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";
import {MultiFlowPump, IWell, IMultiFlowPumpWellFunction, SafeCast, ABDKMathQuad} from "src/pumps/MultiFlowPump.sol";
import {simCapReserve50Percent, from18, to18} from "test/pumps/PumpHelpers.sol";
import {log2, powu, UD60x18, wrap, unwrap} from "prb/math/UD60x18.sol";
import {exp2, log2, powu, UD60x18, wrap, unwrap, uUNIT} from "prb/math/UD60x18.sol";
import {MockStaticWell} from "mocks/wells/MockStaticWell.sol";
import {ReentrancyGuardUpgradeable} from "ozu/security/ReentrancyGuardUpgradeable.sol";
import {Math} from "oz/utils/math/Math.sol";
import "oz/utils/Strings.sol";

contract CapBalanceTest is TestHelper, MultiFlowPump {
    using ABDKMathQuad for bytes16;
    using SafeCast for int256;
    using Math for uint256;
    using Strings for uint256;

    uint256[] lastReserves;
    uint256[] reserves;
    bytes16[][] maxRateChanges;
    bytes16 maxLpSupplyIncrease;
    bytes16 maxLpSupplyDecrease;
    // uint256 MAX_RESERVE = 1e30;
    uint256 MAX_RESERVE = 1e24;
    CapReservesParameters crp;

    address _well;

    ConstantProduct2 public wf;

    constructor() MultiFlowPump() {
        lastReserves = new uint256[](2);
        reserves = new uint256[](2);

        maxLpSupplyIncrease = from18(0.05e18);
        maxLpSupplyDecrease = from18(0.04761904762e18);

        maxRateChanges = new bytes16[][](2);
        maxRateChanges[0] = new bytes16[](2);
        maxRateChanges[1] = new bytes16[](2);
        maxRateChanges[0][1] = from18(0.05e18);
        maxRateChanges[1][0] = from18(0.05e18);

        crp = MultiFlowPump.CapReservesParameters(maxRateChanges, maxLpSupplyIncrease, maxLpSupplyDecrease);

        wf = new ConstantProduct2();

        _well = address(
            new MockStaticWell(
                deployMockTokens(2), Call(address(wf), new bytes(0)), deployPumps(1), address(0), new bytes(0)
            )
        );
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
            CapReservesParameters(maxRateChanges, maxLpSupplyIncrease, maxLpSupplyDecrease)
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
            crp
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
            crp
        );

        assertEq(cappedReserves[0], 979);
        assertEq(cappedReserves[1], 1028);
    }

    function testFuzz_capReserve_oneBlock(uint256[2] memory _lastReserves, uint256[2] memory _reserves) public {
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
            crp
        );

        uint256 ratioDigits = getRatioDigits(address(_well), lastReserves, reserves, 1, crp);
        uint256 precision = numDigits(cappedReserves[0]).min(numDigits(cappedReserves[1])).min(numDigits(reserves[0]))
            .min(numDigits(reserves[1])).min(ratioDigits);

        if (precision >= 2) precision = precision - 2;
        else precision = 1;
        console.log("Digit precision: %s", precision);
        uint256 absolutePrecision = 1;

        uint256 lpTokenSupplyBefore = wf.calcLpTokenSupply(lastReserves, new bytes(0));
        uint256 maxLpTokenSupply = lpTokenSupplyBefore * (1e18 + to18(maxLpSupplyIncrease)) / 1e18;
        uint256 minLpTokenSupply = lpTokenSupplyBefore * (1e18 - to18(maxLpSupplyDecrease)) / 1e18;
        uint256 lpTokenSupplyCapped = wf.calcLpTokenSupply(cappedReserves, new bytes(0));
        console.log("LP Token Supply Before: %s", lpTokenSupplyBefore);
        console.log("LP Token Supply Max: %s", maxLpTokenSupply);
        console.log("LP Token Supply Capped: %s", lpTokenSupplyCapped);
        console.log("LP Token Supply Min: %s", minLpTokenSupply);

        precision = precision.min(numDigits(lpTokenSupplyCapped.sqrt()));
        console.log("LP Token Supply Digits: %s", precision);

        assertApproxGeRelN(lpTokenSupplyCapped, minLpTokenSupply, precision, absolutePrecision);
        assertApproxLeRelN(lpTokenSupplyCapped, maxLpTokenSupply, precision, absolutePrecision);

        assertNotEq(cappedReserves[0], 0);
        assertNotEq(cappedReserves[1], 0);

        if (cappedReserves[0] == 1) return;
        if (cappedReserves[1] == 1) return;

        (uint256 i, uint256 j) = lastReserves[0] > lastReserves[1] ? (0, 1) : (1, 0);

        uint256 rIJMax = lastReserves[i] * (1e18 + to18(maxRateChanges[i][j])) / lastReserves[j];
        uint256 rIJMin = lastReserves[i] * 1e18 / (1 + to18(maxRateChanges[i][j])) / lastReserves[j];
        uint256 rIJCapped = cappedReserves[i] * 1e18 / cappedReserves[j];
        console.log("Max R: %s", rIJMax);
        console.log("Min R: %s", rIJMin);
        console.log("Output R: %s", rIJCapped);
        console.log("Checking Max!");
        assertApproxLeRelN(rIJCapped, rIJMax, precision, absolutePrecision);
        console.log("Checking Min!");
        assertApproxGeRelN(rIJCapped, rIJMin, precision, absolutePrecision);
    }

    function testFuzzInstance_capReserve() public {
        testFuzz_capReserve_xBlock(
            [uint256(668_374_840_427_059_908_583_306_633_348), 999_999_999_999_999_993_316_251_595_735],
            [uint256(935_068_122_923_189_688_180_993_425_409), 944_816_668_711_320_003_773_400_140_733],
            3
        );
    }

    function testFuzz_capReserve_xBlock(
        uint256[2] memory _lastReserves,
        uint256[2] memory _reserves,
        uint256 capExponent
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

        // TODO: Increase bound!!!
        capExponent = bound(capExponent, 1, 10_000);

        uint256[] memory cappedReserves = _capReserves(address(_well), lastReserves, reserves, capExponent, crp);

        assertNotEq(cappedReserves[0], 0);
        assertNotEq(cappedReserves[1], 0);

        if (cappedReserves[0] == 1) return;
        if (cappedReserves[1] == 1) return;

        string[] memory inputs = new string[](20);
        inputs[0] = "python";
        inputs[1] = "test/differential/cap_reserves.py";
        (inputs[2], inputs[3]) = ("-r0", reserves[0].toString());
        (inputs[4], inputs[5]) = ("-r1", reserves[1].toString());
        (inputs[6], inputs[7]) = ("-l0", lastReserves[0].toString());
        (inputs[8], inputs[9]) = ("-l1", lastReserves[1].toString());
        (inputs[10], inputs[11]) = ("-c", capExponent.toString());
        (inputs[12], inputs[13]) = ("-mi", uint256(0.05e18).toString());
        (inputs[14], inputs[15]) = ("-md", uint256(0.04761904762e18).toString());
        (inputs[16], inputs[17]) = ("-mr01", uint256(0.05e18).toString());
        (inputs[18], inputs[19]) = ("-mr10", uint256(0.05e18).toString());
        bytes memory result = vm.ffi(inputs);
        uint256 lpTokenSupplyCapped = wf.calcLpTokenSupply(cappedReserves, new bytes(0));
        uint256 ratioDigits = getRatioDigits(address(_well), lastReserves, reserves, capExponent, crp);

        console.log("LP Token Supply Capped: %s", lpTokenSupplyCapped);
        uint256 precision = numDigits(cappedReserves[0]).min(numDigits(cappedReserves[1])).min(numDigits(reserves[0]))
            .min(numDigits(reserves[1])).min(numDigits(lpTokenSupplyCapped.sqrt()));
        precision = precision.min(ratioDigits);
        if (precision >= 1) precision = precision - 1;
        console.log("Digit precision: %s", precision);

        (uint256 expectedCappedReserve0, uint256 expectedCappedReserve1) = abi.decode(result, (uint256, uint256));
        console.log("R0: %s, R1: %s", expectedCappedReserve0, expectedCappedReserve1);

        assertApproxEqRelN(cappedReserves[0], expectedCappedReserve0, 1, precision);
        assertApproxEqRelN(cappedReserves[1], expectedCappedReserve1, 1, precision);
    }

    function getRatioDigits(
        address well,
        uint256[] memory _lastReserves,
        uint256[] memory _reserves,
        uint256 capExponent,
        CapReservesParameters memory _crp
    ) private view returns (uint256 ratioDigits) {
        Call memory _wf = IWell(well).wellFunction();
        IMultiFlowPumpWellFunction mfpWf = IMultiFlowPumpWellFunction(_wf.target);

        (uint256 i, uint256 j) = _lastReserves[0] > _lastReserves[1] ? (0, 1) : (1, 0);
        uint256 rLast = mfpWf.calcRate(_lastReserves, i, j, _wf.data);
        uint256 r = mfpWf.calcRate(_reserves, i, j, _wf.data);
        if (r < rLast) {
            ratioDigits = rLast.mulDiv(
                ABDKMathQuad.ONE.div(ABDKMathQuad.ONE.add(_crp.maxRateChanges[j][i])).powu(capExponent).to128x128()
                    .toUint256(),
                CAP_PRECISION2
            );
            ratioDigits = numDigits(ratioDigits);
        } else {
            ratioDigits = type(uint256).max;
        }
    }
}
