// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IPump} from "src/interfaces/pumps/IPump.sol";
import {IMultiFlowPumpErrors} from "src/interfaces/pumps/IMultiFlowPumpErrors.sol";
import {IWell, Call} from "src/interfaces/IWell.sol";
import {IInstantaneousPump} from "src/interfaces/pumps/IInstantaneousPump.sol";
import {IMultiFlowPumpWellFunction} from "src/interfaces/IMultiFlowPumpWellFunction.sol";
import {ICumulativePump} from "src/interfaces/pumps/ICumulativePump.sol";
import {ABDKMathQuad} from "src/libraries/ABDKMathQuad.sol";
import {LibBytes16} from "src/libraries/LibBytes16.sol";
import {LibLastReserveBytes} from "src/libraries/LibLastReserveBytes.sol";
import {Math} from "oz/utils/math/Math.sol";
import {SafeCast} from "oz/utils/math/SafeCast.sol";
import {LibMath} from "src/libraries/LibMath.sol";

/**
 * @title MultiFlowPump
 * @author Brendan
 * @notice Stores a geometric EMA and cumulative geometric SMA for each reserve.
 * @dev A Pump designed for use in Beanstalk with 2 tokens.
 *
 * This Pump has 3 main features:
 *  1. Multi-block MEV resistence reserves
 *  2. MEV-resistant Geometric EMA intended for instantaneous reserve queries
 *  3. MEV-resistant Cumulative Geometric intended for SMA reserve queries
 *
 * Note: If an `update` call is made with a reserve of 0, the Geometric mean oracles will be set to 0.
 * Each Well is responsible for ensuring that an `update` call cannot be made with a reserve of 0.
 */
contract MultiFlowPump is IPump, IMultiFlowPumpErrors, IInstantaneousPump, ICumulativePump {
    using LibLastReserveBytes for bytes32;
    using LibBytes16 for bytes32;
    using ABDKMathQuad for bytes16;
    using ABDKMathQuad for uint256;
    using SafeCast for int256;
    using Math for uint256;
    using LibMath for uint256;

    uint256 constant CAP_PRECISION = 1e18;
    uint256 constant CAP_PRECISION2 = 2 ** 128;
    bytes16 constant MAX_CONVERT_TO_128x128 = 0x407dffffffffffffffffffffffffffff;
    uint256 constant MAX_UINT256_SQRT = 340_282_366_920_938_463_463_374_607_431_768_211_455;

    struct PumpState {
        uint40 lastTimestamp;
        uint256[] lastReserves;
        bytes16[] emaReserves;
        bytes16[] cumulativeReserves;
    }

    struct CapReservesParameters {
        bytes16[][] maxRateChanges;
        bytes16 maxLpSupplyIncrease;
        bytes16 maxLpSupplyDecrease;
    }

    struct CapRatesVariables {
        uint256 r;
        uint256 rLast;
        uint256 rLimit;
        uint256[] ratios;
    }

    //////////////////// PUMP ////////////////////

    /**
     * @dev Update the Pump's manipulation resistant reserve balances for a given `well` with `reserves`.
     */
    function update(uint256[] calldata reserves, bytes calldata data) external {
        // Require two token well
        if (reserves.length != 2) {
            revert TooManyTokens();
        }

        (bytes16 alpha, uint256 capInterval, CapReservesParameters memory crp) =
            abi.decode(data, (bytes16, uint256, CapReservesParameters));
        uint256 numberOfReserves = reserves.length;
        PumpState memory pumpState;

        // All reserves are stored starting at the msg.sender address slot in storage.
        bytes32 slot = _getSlotForAddress(msg.sender);

        // Read: Last Timestamp & Last Reserves
        (, pumpState.lastTimestamp, pumpState.lastReserves) = slot.readLastReserves();

        // If the last timestamp is 0, then the pump has never been used before.
        if (pumpState.lastTimestamp == 0) {
            _init(slot, uint40(block.timestamp), reserves);
            return;
        }

        bytes16 alphaN;
        bytes16 deltaTimestampBytes;
        uint256 capExponent;
        // Isolate in brackets to prevent stack too deep errors
        {
            uint256 deltaTimestamp = _getDeltaTimestamp(pumpState.lastTimestamp);
            // If no time has passed, don't update the pump reserves.
            if (deltaTimestamp == 0) return;
            alphaN = alpha.powu(deltaTimestamp);
            deltaTimestampBytes = deltaTimestamp.fromUInt();
            // Round up in case capInterval > block time to guarantee capExponent > 0 if time has passed since the last update.
            capExponent = calcCapExponent(deltaTimestamp, capInterval);
        }

        pumpState.lastReserves = _capReserves(msg.sender, pumpState.lastReserves, reserves, capExponent, crp);

        // Read: Cumulative & EMA Reserves
        // Start at the slot after `pumpState.lastReserves`
        uint256 numSlots = _getSlotsOffset(numberOfReserves);
        assembly {
            slot := add(slot, numSlots)
        }
        pumpState.emaReserves = slot.readBytes16(numberOfReserves);
        assembly {
            slot := add(slot, numSlots)
        }
        pumpState.cumulativeReserves = slot.readBytes16(numberOfReserves);

        bytes16 lastReserve;
        for (uint256 i; i < numberOfReserves; ++i) {
            lastReserve = pumpState.lastReserves[i].fromUIntToLog2();
            pumpState.emaReserves[i] =
                lastReserve.mul((ABDKMathQuad.ONE.sub(alphaN))).add(pumpState.emaReserves[i].mul(alphaN));
            pumpState.cumulativeReserves[i] = pumpState.cumulativeReserves[i].add(lastReserve.mul(deltaTimestampBytes));
        }

        // Write: Cumulative & EMA Reserves
        // Order matters: work backwards to avoid using a new memory var to count up
        slot.storeBytes16(pumpState.cumulativeReserves);
        assembly {
            slot := sub(slot, numSlots)
        }
        slot.storeBytes16(pumpState.emaReserves);
        assembly {
            slot := sub(slot, numSlots)
        }

        // Write: Last Timestamp & Last Reserves
        slot.storeLastReserves(uint40(block.timestamp), pumpState.lastReserves);
    }

    /**
     * @dev On first update for a particular Well, initialize oracle with
     * reserves data.
     */
    function _init(bytes32 slot, uint40 lastTimestamp, uint256[] memory reserves) internal {
        uint256 numberOfReserves = reserves.length;
        bytes16[] memory byteReserves = new bytes16[](numberOfReserves);

        // Skip {_capReserve} since we have no prior reference

        for (uint256 i; i < numberOfReserves; ++i) {
            uint256 _reserve = reserves[i];
            if (_reserve == 0) return;
            byteReserves[i] = _reserve.fromUIntToLog2();
        }

        // Write: Last Timestamp & Last Reserves
        slot.storeLastReserves(lastTimestamp, reserves);

        // Write: EMA Reserves
        // Start at the slot after `byteReserves`
        uint256 numSlots = _getSlotsOffset(numberOfReserves);
        assembly {
            slot := add(slot, numSlots)
        }
        slot.storeBytes16(byteReserves); // EMA Reserves
    }

    //////////////////// LAST RESERVES ////////////////////

    /**
     * @dev Reads the last capped reserves from the Pump from storage.
     */
    function readLastCappedReserves(
        address well,
        bytes memory
    ) public view returns (uint256[] memory lastCappedReserves) {
        uint8 numberOfReserves;
        (numberOfReserves,, lastCappedReserves) = _getSlotForAddress(well).readLastReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
    }

    /**
     * @dev Reads the capped reserves from the Pump updated to the current block using the current reserves of `well`.
     */
    function readCappedReserves(
        address well,
        bytes calldata data
    ) external view returns (uint256[] memory cappedReserves) {
        (, uint256 capInterval, CapReservesParameters memory crp) =
            abi.decode(data, (bytes16, uint256, CapReservesParameters));
        bytes32 slot = _getSlotForAddress(well);
        uint256[] memory currentReserves = IWell(well).getReserves();
        uint8 numberOfReserves;
        uint40 lastTimestamp;
        (numberOfReserves, lastTimestamp, cappedReserves) = slot.readLastReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
        uint256 deltaTimestamp = _getDeltaTimestamp(lastTimestamp);
        if (deltaTimestamp == 0) {
            return cappedReserves;
        }

        uint256 capExponent = calcCapExponent(deltaTimestamp, capInterval);
        cappedReserves = _capReserves(well, cappedReserves, currentReserves, capExponent, crp);
    }

    /**
     * @notice Cap `reserves` to have at most a maximum % increase/decrease in rate and a maximum % increase/decrease in total liquidity
     * in relation to `lastReserves` based on the parameters defined in `crp` and the time passed since the last update, which is used
     * to calculate `capExponent`.
     * @param well The address of the Well
     * @param lastReserves The last capped reserves.
     * @param reserves The current reserves being capped.
     * @param capExponent The exponent to raise the all % changes to.
     * @param crp The parameters for capping reserves. See {CapReservesParameters}.
     * @return cappedReserves The current reserves capped to the maximum % changes defined by `crp`.
     */
    function _capReserves(
        address well,
        uint256[] memory lastReserves,
        uint256[] memory reserves,
        uint256 capExponent,
        CapReservesParameters memory crp
    ) internal view returns (uint256[] memory cappedReserves) {
        Call memory wf = IWell(well).wellFunction();
        IMultiFlowPumpWellFunction mfpWf = IMultiFlowPumpWellFunction(wf.target);

        // The order that the LP token supply and the rates are capped are dependent upon the values of the reserves to maximize precision.
        cappedReserves = _capLpTokenSupply(lastReserves, reserves, capExponent, crp, mfpWf, wf.data, true);

        // If `_capLpTokenSupply` returns an empty array, then the rates should be capped first.
        if (cappedReserves.length == 0) {
            cappedReserves = _capRates(lastReserves, reserves, capExponent, crp, mfpWf, wf.data);

            cappedReserves = _capLpTokenSupply(lastReserves, cappedReserves, capExponent, crp, mfpWf, wf.data, false);
        } else {
            cappedReserves = _capRates(lastReserves, cappedReserves, capExponent, crp, mfpWf, wf.data);
        }
    }

    /**
     * @dev Cap the change in ratio of `reserves` to a maximum % change from `lastReserves`.
     */
    function _capRates(
        uint256[] memory lastReserves,
        uint256[] memory reserves,
        uint256 capExponent,
        CapReservesParameters memory crp,
        IMultiFlowPumpWellFunction mfpWf,
        bytes memory data
    ) internal view returns (uint256[] memory cappedReserves) {
        cappedReserves = reserves;
        // Part 1: Cap Rates
        // Use the larger reserve as the numerator for the ratio to maximize precision
        (uint256 i, uint256 j) = lastReserves[0] > lastReserves[1] ? (0, 1) : (1, 0);
        CapRatesVariables memory crv;
        crv.rLast = mfpWf.calcRate(lastReserves, i, j, data);
        crv.r = mfpWf.calcRate(cappedReserves, i, j, data);

        // If the ratio increased, check that it didn't increase above the max.
        if (crv.r > crv.rLast) {
            bytes16 tempExp = ABDKMathQuad.ONE.add(crp.maxRateChanges[i][j]).powu(capExponent);
            crv.rLimit = tempExp.cmp(MAX_CONVERT_TO_128x128) != -1
                ? crv.rLimit = type(uint256).max
                : crv.rLast.mulDivOrMax(tempExp.to128x128().toUint256(), CAP_PRECISION2);
            if (crv.r > crv.rLimit) {
                calcReservesAtRatioSwap(mfpWf, crv.rLimit, cappedReserves, i, j, data);
            }
            // If the ratio decreased, check that it didn't overflow during calculation
        } else if (crv.r < crv.rLast) {
            bytes16 tempExp = ABDKMathQuad.ONE.div(ABDKMathQuad.ONE.add(crp.maxRateChanges[j][i])).powu(capExponent);
            // Check for overflow before converting to 128x128
            if (tempExp.cmp(MAX_CONVERT_TO_128x128) != -1) {
                crv.rLimit = 0; // Set limit to 0 in case of overflow
            } else {
                crv.rLimit = crv.rLast.mulDiv(tempExp.to128x128().toUint256(), CAP_PRECISION2);
            }
            if (crv.r < crv.rLimit) {
                calcReservesAtRatioSwap(mfpWf, crv.rLimit, cappedReserves, i, j, data);
            }
        }
    }

    /**
     * @dev Cap the change in LP Token Supply of `reserves` to a maximum % change from `lastReserves`.
     */
    function _capLpTokenSupply(
        uint256[] memory lastReserves,
        uint256[] memory reserves,
        uint256 capExponent,
        CapReservesParameters memory crp,
        IMultiFlowPumpWellFunction mfpWf,
        bytes memory data,
        bool returnIfBelowMin
    ) internal view returns (uint256[] memory cappedReserves) {
        cappedReserves = reserves;
        // Part 2: Cap LP Token Supply Change
        uint256 lastLpTokenSupply = tryCalcLpTokenSupply(mfpWf, lastReserves, data);
        uint256 lpTokenSupply = tryCalcLpTokenSupply(mfpWf, cappedReserves, data);

        // If LP Token Supply increased, check that it didn't increase above the max.
        if (lpTokenSupply > lastLpTokenSupply) {
            bytes16 tempExp = ABDKMathQuad.ONE.add(crp.maxLpSupplyIncrease).powu(capExponent);
            uint256 maxLpTokenSupply = tempExp.cmp(MAX_CONVERT_TO_128x128) != -1
                ? type(uint256).max
                : lastLpTokenSupply.mulDiv(tempExp.to128x128().toUint256(), CAP_PRECISION2);

            if (lpTokenSupply > maxLpTokenSupply) {
                // If `_capLpTokenSupply` decreases the reserves, cap the ratio first, to maximize precision.
                if (returnIfBelowMin) return new uint256[](0);
                cappedReserves = tryCalcLPTokenUnderlying(mfpWf, maxLpTokenSupply, cappedReserves, lpTokenSupply, data);
            }
            // If LP Token Suppply decreased, check that it didn't increase below the min.
        } else if (lpTokenSupply < lastLpTokenSupply) {
            uint256 minLpTokenSupply = lastLpTokenSupply
                * (ABDKMathQuad.ONE.sub(crp.maxLpSupplyDecrease)).powu(capExponent).to128x128().toUint256() / CAP_PRECISION2;
            if (lpTokenSupply < minLpTokenSupply) {
                cappedReserves = tryCalcLPTokenUnderlying(mfpWf, minLpTokenSupply, cappedReserves, lpTokenSupply, data);
            }
        }
    }

    //////////////////// EMA RESERVES ////////////////////

    function readLastInstantaneousReserves(
        address well,
        bytes memory
    ) external view returns (uint256[] memory emaReserves) {
        bytes32 slot = _getSlotForAddress(well);
        uint8 numberOfReserves = slot.readNumberOfReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
        uint256 offset = _getSlotsOffset(numberOfReserves);
        assembly {
            slot := add(slot, offset)
        }
        bytes16[] memory byteReserves = slot.readBytes16(numberOfReserves);
        emaReserves = new uint256[](numberOfReserves);
        for (uint256 i; i < numberOfReserves; ++i) {
            emaReserves[i] = byteReserves[i].pow_2ToUInt();
        }
    }

    function readInstantaneousReserves(
        address well,
        bytes memory data
    ) external view returns (uint256[] memory emaReserves) {
        (bytes16 alpha, uint256 capInterval, CapReservesParameters memory crp) =
            abi.decode(data, (bytes16, uint256, CapReservesParameters));
        bytes32 slot = _getSlotForAddress(well);
        uint256[] memory reserves = IWell(well).getReserves();
        (uint8 numberOfReserves, uint40 lastTimestamp, uint256[] memory lastReserves) = slot.readLastReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
        uint256 offset = _getSlotsOffset(numberOfReserves);
        assembly {
            slot := add(slot, offset)
        }
        bytes16[] memory lastEmaReserves = slot.readBytes16(numberOfReserves);
        emaReserves = new uint256[](numberOfReserves);
        uint256 deltaTimestamp = _getDeltaTimestamp(lastTimestamp);
        // If no time has passed, return last EMA reserves.
        if (deltaTimestamp == 0) {
            for (uint256 i; i < numberOfReserves; ++i) {
                emaReserves[i] = lastEmaReserves[i].pow_2ToUInt();
            }
            return emaReserves;
        }
        uint256 capExponent = calcCapExponent(deltaTimestamp, capInterval);
        lastReserves = _capReserves(well, lastReserves, reserves, capExponent, crp);
        bytes16 alphaN = alpha.powu(deltaTimestamp);
        for (uint256 i; i < numberOfReserves; ++i) {
            emaReserves[i] = lastReserves[i].fromUIntToLog2().mul((ABDKMathQuad.ONE.sub(alphaN))).add(
                lastEmaReserves[i].mul(alphaN)
            ).pow_2ToUInt();
        }
    }

    //////////////////// CUMULATIVE RESERVES ////////////////////

    /**
     * @notice Read the latest cumulative reserves of `well`.
     */
    function readLastCumulativeReserves(
        address well,
        bytes memory
    ) external view returns (bytes16[] memory cumulativeReserves) {
        bytes32 slot = _getSlotForAddress(well);
        uint8 numberOfReserves = slot.readNumberOfReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
        uint256 offset = _getSlotsOffset(numberOfReserves) << 1;
        assembly {
            slot := add(slot, offset)
        }
        cumulativeReserves = slot.readBytes16(numberOfReserves);
    }

    function readCumulativeReserves(
        address well,
        bytes memory data
    ) external view returns (bytes memory cumulativeReserves) {
        bytes16[] memory byteCumulativeReserves = _readCumulativeReserves(well, data);
        cumulativeReserves = abi.encode(byteCumulativeReserves);
    }

    function _readCumulativeReserves(
        address well,
        bytes memory data
    ) internal view returns (bytes16[] memory cumulativeReserves) {
        (, uint256 capInterval, CapReservesParameters memory crp) =
            abi.decode(data, (bytes16, uint256, CapReservesParameters));
        bytes32 slot = _getSlotForAddress(well);
        uint256[] memory reserves = IWell(well).getReserves();
        (uint8 numberOfReserves, uint40 lastTimestamp, uint256[] memory lastReserves) = slot.readLastReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
        uint256 offset = _getSlotsOffset(numberOfReserves) << 1;
        assembly {
            slot := add(slot, offset)
        }
        cumulativeReserves = slot.readBytes16(numberOfReserves);
        uint256 deltaTimestamp = _getDeltaTimestamp(lastTimestamp);
        // If no time has passed, return last cumulative reserves.
        if (deltaTimestamp == 0) {
            return cumulativeReserves;
        }
        bytes16 deltaTimestampBytes = deltaTimestamp.fromUInt();
        uint256 capExponent = calcCapExponent(deltaTimestamp, capInterval);
        lastReserves = _capReserves(well, lastReserves, reserves, capExponent, crp);
        // Currently, there is so support for overflow.
        for (uint256 i; i < cumulativeReserves.length; ++i) {
            cumulativeReserves[i] = cumulativeReserves[i].add(lastReserves[i].fromUIntToLog2().mul(deltaTimestampBytes));
        }
    }

    function readTwaReserves(
        address well,
        bytes calldata startCumulativeReserves,
        uint256 startTimestamp,
        bytes memory data
    ) public view returns (uint256[] memory twaReserves, bytes memory cumulativeReserves) {
        bytes16[] memory byteCumulativeReserves = _readCumulativeReserves(well, data);
        bytes16[] memory byteStartCumulativeReserves = abi.decode(startCumulativeReserves, (bytes16[]));
        twaReserves = new uint256[](byteCumulativeReserves.length);

        // Overflow is desired on `startTimestamp`, so SafeCast is not used.
        bytes16 deltaTimestamp = _getDeltaTimestamp(uint40(startTimestamp)).fromUInt();
        if (deltaTimestamp == bytes16(0)) {
            revert NoTimePassed();
        }
        for (uint256 i; i < byteCumulativeReserves.length; ++i) {
            // Currently, there is no support for overflow.
            twaReserves[i] =
                (byteCumulativeReserves[i].sub(byteStartCumulativeReserves[i])).div(deltaTimestamp).pow_2ToUInt();
        }
        cumulativeReserves = abi.encode(byteCumulativeReserves);
    }

    //////////////////// HELPERS ////////////////////

    /**
     * @dev Calculate the cap exponent for a given `deltaTimestamp` and `capInterval`.
     */
    function calcCapExponent(uint256 deltaTimestamp, uint256 capInterval) private pure returns (uint256 capExponent) {
        capExponent = ((deltaTimestamp - 1) / capInterval + 1);
    }

    /**
     * @dev Calculates the capped reserves given a rate limit.
     */
    function calcReservesAtRatioSwap(
        IMultiFlowPumpWellFunction mfpWf,
        uint256 rLimit,
        uint256[] memory reserves,
        uint256 i,
        uint256 j,
        bytes memory data
    ) private view returns (uint256[] memory) {
        uint256[] memory ratios = new uint256[](2);
        ratios[i] = rLimit;
        ratios[j] = CAP_PRECISION;
        // Use a minimum of 1 for reserve. Geometric means will be set to 0 if a reserve is 0.
        uint256 cappedReserveI = Math.max(tryCalcReserveAtRatioSwap(mfpWf, reserves, i, ratios, data), 1);
        reserves[j] = Math.max(tryCalcReserveAtRatioSwap(mfpWf, reserves, j, ratios, data), 1);
        reserves[i] = cappedReserveI;
        return reserves;
    }

    /**
     * @dev Convert an `address` into a `bytes32` by zero padding the right 12 bytes.
     */
    function _getSlotForAddress(address addressValue) internal pure returns (bytes32 _slot) {
        _slot = bytes32(bytes20(addressValue)); // Because right padded, no collision on adjacent
    }

    /**
     * @dev Get the slot number that contains the `n`th element of an array.
     * slots are seperated by 32 bytes to allow for future expansion of the Pump (i.e supporting Well with more than 3 tokens).
     */
    function _getSlotsOffset(uint256 numberOfReserves) internal pure returns (uint256 _slotsOffset) {
        _slotsOffset = ((numberOfReserves - 1) / 2 + 1) << 5;
    }

    /**
     * @dev Get the delta between the current and provided timestamp as a `uint256`.
     */
    function _getDeltaTimestamp(uint40 lastTimestamp) internal view returns (uint256 _deltaTimestamp) {
        return uint256(uint40(block.timestamp) - lastTimestamp);
    }

    /**
     * @dev Assumes that if `calcReserveAtRatioSwap` fails, it fails because of overflow.
     * If the call fails, returns the maximum possible return value for `calcReserveAtRatioSwap`.
     */
    function tryCalcReserveAtRatioSwap(
        IMultiFlowPumpWellFunction wf,
        uint256[] memory reserves,
        uint256 i,
        uint256[] memory ratios,
        bytes memory data
    ) internal view returns (uint256 reserve) {
        try wf.calcReserveAtRatioSwap(reserves, i, ratios, data) returns (uint256 _reserve) {
            reserve = _reserve;
        } catch {
            reserve = type(uint256).max;
        }
    }

    /**
     * @dev Assumes that if `calcLpTokenSupply` fails, it fails because of overflow.
     * If it fails, returns the maximum possible return value for `calcLpTokenSupply`.
     */
    function tryCalcLpTokenSupply(
        IMultiFlowPumpWellFunction wf,
        uint256[] memory reserves,
        bytes memory data
    ) internal view returns (uint256 lpTokenSupply) {
        try wf.calcLpTokenSupply(reserves, data) returns (uint256 _lpTokenSupply) {
            lpTokenSupply = _lpTokenSupply;
        } catch {
            lpTokenSupply = MAX_UINT256_SQRT;
        }
    }

    /**
     * @dev Assumes that if `calcLPTokenUnderlying` fails, it fails because of overflow.
     * If the call fails, returns the maximum possible return value for `calcLPTokenUnderlying`.
     * Also, enforces a minimum of 1 for each reserve.
     */
    function tryCalcLPTokenUnderlying(
        IMultiFlowPumpWellFunction wf,
        uint256 lpTokenAmount,
        uint256[] memory reserves,
        uint256 lpTokenSupply,
        bytes memory data
    ) internal view returns (uint256[] memory underlyingAmounts) {
        try wf.calcLPTokenUnderlying(lpTokenAmount, reserves, lpTokenSupply, data) returns (
            uint256[] memory _underlyingAmounts
        ) {
            underlyingAmounts = _underlyingAmounts;
            for (uint256 i; i < underlyingAmounts.length; ++i) {
                if (underlyingAmounts[i] == 0) {
                    underlyingAmounts[i] = 1;
                }
            }
        } catch {
            underlyingAmounts = new uint256[](reserves.length);
            for (uint256 i; i < reserves.length; ++i) {
                underlyingAmounts[i] = type(uint256).max;
            }
        }
    }
}
