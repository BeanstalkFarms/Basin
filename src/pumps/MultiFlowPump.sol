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

import {console} from "forge-std/console.sol";

/**
 * @title MultiFlowPump
 * @author Publius
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
    
    uint256 CAP_PRECISION = 1e18;
    uint256 CAP_PRECISION2 = 2**128;
    bytes16 MAX_CONVERT_TO_128x128 = 0x407dffffffffffffffffffffffffffff;

    struct PumpState {
        uint40 lastTimestamp;
        uint256[] lastReserves;
        bytes16[] emaReserves;
        bytes16[] cumulativeReserves;
    }

    struct CapReservesParameters {
        bytes16[][] maxRatioChanges;
        bytes16 maxLpTokenIncrease;
        bytes16 maxLpTokenDecrease;
    }

    //////////////////// PUMP ////////////////////

    function update(uint256[] calldata reserves, bytes calldata data) external {
        (bytes16 alpha, uint256 capInterval, CapReservesParameters memory crp) = abi.decode(data, (bytes16, uint256, CapReservesParameters));
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
            console.log("Delta Timestamp: %s", deltaTimestamp);
            console.log("Alpha: %s", uint256(alpha.to128x128()));
            alphaN = alpha.powu(deltaTimestamp);
            console.log("Alpha N: %s", uint256(alphaN.to128x128()));
            deltaTimestampBytes = deltaTimestamp.fromUInt();
            // Round up in case capInterval > block time to guarantee capExponent > 0 if time has passed since the last update.
            capExponent = ((deltaTimestamp - 1) / capInterval + 1);
        }

        (numberOfReserves, pumpState.lastTimestamp, pumpState.lastReserves) = slot.readLastReserves();
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
            pumpState.cumulativeReserves[i] =
                pumpState.cumulativeReserves[i].add(lastReserve.mul(deltaTimestampBytes));
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
    function readLastCappedReserves(address well, bytes memory) public view returns (uint256[] memory lastCappedReserves) {
        uint8 numberOfReserves;
        (numberOfReserves, , lastCappedReserves) = _getSlotForAddress(well).readLastReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
    }

    /**
     * @dev Reads the capped reserves from the Pump updated to the current block using the current reserves of `well`.
     */
    function readCappedReserves(address well, bytes calldata data) external view returns (uint256[] memory cappedReserves) {
        (, uint256 capInterval, CapReservesParameters memory crp) = abi.decode(data, (bytes16, uint256, CapReservesParameters));
        bytes32 slot = _getSlotForAddress(well);
        uint256[] memory currentReserves = IWell(well).getReserves();
        uint8 numberOfReserves; uint40 lastTimestamp;
        (numberOfReserves, lastTimestamp, cappedReserves) = slot.readLastReserves();
        if (numberOfReserves == 0) {
            revert NotInitialized();
        }
        uint256 deltaTimestamp = _getDeltaTimestamp(lastTimestamp);
        if (deltaTimestamp == 0) {
            return cappedReserves;
        }

        uint256 capExponent = ((deltaTimestamp - 1) / capInterval + 1);
        cappedReserves = _capReserves(well, cappedReserves, currentReserves, capExponent, crp);
    }

    struct CapReservesVariables {
        uint256 rLast;
        bytes16 tempExp;
        uint256 rMaxIJ;
        uint256 rMinIJ;
        uint256[] ratios;
    }

    function _capReserves(
        address well,
        uint256[] memory lastReserves,
        uint256[] memory reserves,
        uint256 capExponent,
        CapReservesParameters memory crp
    ) internal view returns (uint256[] memory cappedReserves) {
        // Assume two token well
        console.log(reserves.length);
        if (reserves.length != 2) {
            revert TooManyTokens();
        }

        cappedReserves = reserves;

        Call memory wf = IWell(well).wellFunction();
        IMultiFlowPumpWellFunction mfpWf = IMultiFlowPumpWellFunction(wf.target);

        {
            // Part 1: Cap Ratios
            (uint256 i, uint256 j) = lastReserves[0] > lastReserves[1] ? (0, 1) : (1, 0);
            CapReservesVariables memory crv;
            crv.rLast = mfpWf.calcRate(lastReserves, i, j, wf.data);
            console.log("rLast: %s", crv.rLast);

            console.logInt(ABDKMathQuad.ONE.add(crp.maxRatioChanges[i][j]).to128x128());
            console.log(capExponent);
            console.logBytes16(ABDKMathQuad.ONE.add(crp.maxRatioChanges[i][j]).powu(capExponent));
            
            console.logInt(crp.maxRatioChanges[i][j].powu(capExponent).to128x128());

            crv.tempExp = ABDKMathQuad.ONE.add(crp.maxRatioChanges[i][j]).powu(capExponent);
            if (crv.tempExp.cmp(MAX_CONVERT_TO_128x128) != -1) {
                console.log("Ratio Exp Above Max");
            // if (crv.tempExp == ABDKMathQuad.POSITIVE_INFINITY) {
                crv.rMaxIJ = type(uint256).max;
            } else {
                console.log("Ratio Exp Below Max");
                console.log("Temp Exp: %s", crv.tempExp.to128x128().toUint256());
                crv.rMaxIJ = crv.rLast.mulDiv(crv.tempExp.to128x128().toUint256(), CAP_PRECISION2);
                // crv.rMaxIJ = crv.rLast * crv.tempExp.to128x128().toUint256() / CAP_PRECISION2;
            }
            console.log("rMaxIJ 1: %s", crv.rMaxIJ);
            crv.rMinIJ = crv.rLast.mulDiv(ABDKMathQuad.ONE.div(ABDKMathQuad.ONE.add(crp.maxRatioChanges[j][i])).powu(capExponent).to128x128().toUint256(), CAP_PRECISION2);
            console.log("rMinIJ 1: %s", crv.rMinIJ);
            // crv.rMaxIJ = crv.rLast * (CAP_PRECISION + crp.maxRatioChanges[i][j]) / CAP_PRECISION; // TODO: Fix cap exponent
            // crv.rMinIJ = crv.rLast * (CAP_PRECISION - 1 / (1 + crp.maxRatioChanges[j][i])) / CAP_PRECISION; // TODO: Fix cap exponent
            console.log("rMaxIJ 2: %s", crv.rLast * (CAP_PRECISION + 0.05e18) / CAP_PRECISION);
            console.log("rMaxIJ 2: %s", crv.rLast * (CAP_PRECISION - 0.04761904762e18) / CAP_PRECISION);

            console.log("rIJ: %s", cappedReserves[i] * CAP_PRECISION / cappedReserves[j]);

            if (cappedReserves[i] * CAP_PRECISION / cappedReserves[j] > crv.rMaxIJ) {
                console.log("Ratio Above Max");
                crv.ratios = new uint256[](2);
                crv.ratios[i] = crv.rMaxIJ;
                crv.ratios[j] = CAP_PRECISION;
                console.log("Ratio 0: %s", crv.ratios[0]);
                console.log("Ratio 1: %s", crv.ratios[1]);
                console.log("CRi", cappedReserves[i]);
                // Use a minimum of 1 for reserve. Geometric means will be set to 0 if a reserve is 0.
                // TODO: Make sure this works.
                uint256 cappedReserveI = Math.max(tryCalcReserveAtRatioSwap(mfpWf, cappedReserves, i, crv.ratios, wf.data), 1);
                console.log("CRi", cappedReserves[i]);
                cappedReserves[j] = Math.max(tryCalcReserveAtRatioSwap(mfpWf, cappedReserves, j, crv.ratios, wf.data), 1);
                cappedReserves[i] = cappedReserveI;
            } else if (cappedReserves[i] * CAP_PRECISION / cappedReserves[j] < crv.rMinIJ) {
                console.log("Ratio Below Max");
                crv.ratios = new uint256[](2);
                crv.ratios[i] = crv.rMinIJ;
                crv.ratios[j] = CAP_PRECISION;
                console.log("2");
                console.log("Ratio 0: %s", crv.ratios[0]);
                console.log("Ratio 1: %s", crv.ratios[1]);
                // Use a minimum of 1 for reserve. Geometric means will be set to 0 if a reserve is 0.
                console.log("Try 0: %s", tryCalcReserveAtRatioSwap(mfpWf, cappedReserves, i, crv.ratios, wf.data));
                console.log("Try 1: %s", tryCalcReserveAtRatioSwap(mfpWf, cappedReserves, j, crv.ratios, wf.data));
                uint256 cappedReserveI = Math.max(tryCalcReserveAtRatioSwap(mfpWf, cappedReserves, i, crv.ratios, wf.data), 1);
                cappedReserves[j] = Math.max(tryCalcReserveAtRatioSwap(mfpWf, cappedReserves, j, crv.ratios, wf.data), 1);
                cappedReserves[i] = cappedReserveI;
            }
        }

        console.log("Partway Capped 0: %s", cappedReserves[0]);
        console.log("Partway Capped 1: %s", cappedReserves[1]);

        {
            // Part 2: Cap LP Token Supply Change
            uint256 lastLpTokenSupply = tryCalcLpTokenSupply(mfpWf, lastReserves, wf.data);
            uint256 lpTokenSupply = tryCalcLpTokenSupply(mfpWf, cappedReserves, wf.data);
            console.log("lastLpTokenSupply: %s", lastLpTokenSupply);
            console.log("lpTokenSupply: %s", lpTokenSupply);
            console.log("Cap Exp: %s", capExponent);
            bytes16 tempExp = ABDKMathQuad.ONE.add(crp.maxLpTokenIncrease).powu(capExponent);
            console.logBytes16(tempExp);
            uint256 maxLpTokenSupply;
            if (tempExp.cmp(MAX_CONVERT_TO_128x128) != -1) {
                console.log("Token Supply Exp Above max");
                maxLpTokenSupply = type(uint256).max;
            } else {
                console.log("Token Supply Exp Below Max");
                console.logInt(tempExp.to128x128());
                maxLpTokenSupply = lastLpTokenSupply.mulDiv(tempExp.to128x128().toUint256(), CAP_PRECISION2);
            }
            console.log(maxLpTokenSupply);
            uint256 minLpTokenSupply = lastLpTokenSupply * (ABDKMathQuad.ONE.sub(crp.maxLpTokenDecrease)).powu(capExponent).to128x128().toUint256() / CAP_PRECISION2;
            console.log("maxLpTokenSupply 1: %s", maxLpTokenSupply);
            console.log("minLpTokenSupply 1: %s", minLpTokenSupply);
            console.log("maxLpTokenSupply 2: %s", lastLpTokenSupply * (CAP_PRECISION + 0.05e18) / CAP_PRECISION);
            console.log("minLpTokenSupply 2: %s", lastLpTokenSupply * (CAP_PRECISION - 0.04761904762e18) / CAP_PRECISION);
            // uint256 maxLpTokenSupply = lastLpTokenSupply * (CAP_PRECISION + crp.maxLpTokenIncrease) / CAP_PRECISION;
            // uint256 minLpTokenSupply = lastLpTokenSupply * (CAP_PRECISION - crp.maxLpTokenDecrease) / CAP_PRECISION;

            if (lpTokenSupply > maxLpTokenSupply) {
                console.log("Supply Capped!!!!");
                cappedReserves = tryCalcLPTokenUnderlying(mfpWf, maxLpTokenSupply, cappedReserves, lpTokenSupply, wf.data);
                if (cappedReserves[0] == 0) cappedReserves[0] = 1;
                if (cappedReserves[1] == 0) cappedReserves[1] = 1;
            } else if (lpTokenSupply < minLpTokenSupply) {
                console.log("Supply Capped!!!!");
                cappedReserves = tryCalcLPTokenUnderlying(mfpWf, minLpTokenSupply, cappedReserves, lpTokenSupply, wf.data);
                if (cappedReserves[0] == 0) cappedReserves[0] = 1;
                if (cappedReserves[1] == 0) cappedReserves[1] = 1;
            }
        }

        console.log("Final Capped Reserve 0: %s", cappedReserves[0]);
        console.log("Final Capped Reserve 1: %s", cappedReserves[1]);
    }

    //////////////////// EMA RESERVES ////////////////////

    function readLastInstantaneousReserves(address well, bytes memory) external view returns (uint256[] memory emaReserves) {
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
        (bytes16 alpha, uint256 capInterval, CapReservesParameters memory crp) = abi.decode(data, (bytes16, uint256, CapReservesParameters));
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
        console.log("B");
        emaReserves = new uint256[](numberOfReserves);
        uint256 deltaTimestamp = _getDeltaTimestamp(lastTimestamp);
        // If no time has passed, return last EMA reserves.
        if (deltaTimestamp == 0) {
            for (uint256 i; i < numberOfReserves; ++i) {
                emaReserves[i] = lastEmaReserves[i].pow_2ToUInt();
            }
            return emaReserves;
        }
        console.log("C");
        uint256 capExponent = ((deltaTimestamp - 1) / capInterval + 1);
        console.log("D");
        console.logBytes16(crp.maxLpTokenIncrease);
        console.logBytes16(crp.maxLpTokenDecrease);
        console.logBytes16(crp.maxRatioChanges[0][1]);
        console.logBytes16(crp.maxRatioChanges[1][0]);
        console.log("Cap Exponent: %s", capExponent);
        lastReserves = _capReserves(well, lastReserves, reserves, capExponent, crp);
        console.log("E");
        console.log("Delta Timestamp: %s", deltaTimestamp);
        console.log("Alpha: %s", uint256(alpha.to128x128()));
        bytes16 alphaN = alpha.powu(deltaTimestamp);
        console.log("Alpha N: %s", uint256(alphaN.to128x128()));
        for (uint256 i; i < numberOfReserves; ++i) {
            console.log("%s---------------------------", i);
            console.log("Last Ema Reserve: %s", lastEmaReserves[i].pow_2ToUInt());
            console.log("Reserve: %s", lastReserves[i]);
            emaReserves[i] =
                lastReserves[i].fromUIntToLog2().mul((ABDKMathQuad.ONE.sub(alphaN))).add(lastEmaReserves[i].mul(alphaN)).pow_2ToUInt();
        }
    }

    //////////////////// CUMULATIVE RESERVES ////////////////////

    /**
     * @notice Read the latest cumulative reserves of `well`.
     */
    function readLastCumulativeReserves(address well, bytes memory) external view returns (bytes16[] memory cumulativeReserves) {
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

    function _readCumulativeReserves(address well, bytes memory data) internal view returns (bytes16[] memory cumulativeReserves) {
        (, uint256 capInterval, CapReservesParameters memory crp) = abi.decode(data, (bytes16, uint256, CapReservesParameters));
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
        uint256 capExponent = ((deltaTimestamp - 1) / capInterval + 1);
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
     * @dev Convert an `address` into a `bytes32` by zero padding the right 12 bytes.
     */
    function _getSlotForAddress(address addressValue) internal pure returns (bytes32 _slot) {
        _slot = bytes32(bytes20(addressValue)); // Because right padded, no collision on adjacent
    }

    /**
     * @dev Get the starting byte of the slot that contains the `n`th element of an array.
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
     */
    function tryCalcLpTokenSupply(
        IMultiFlowPumpWellFunction wf,
        uint256[] memory reserves,
        bytes memory data
    ) internal view returns (uint256 lpTokenSupply) {
        try wf.calcLpTokenSupply(reserves, data) returns (uint256 _lpTokenSupply) {
            lpTokenSupply = _lpTokenSupply;
        } catch {
            lpTokenSupply = type(uint256).max;
        }
    }

    /**
     * @dev Assumes that if `calcLPTokenUnderlying` fails, it fails because of overflow.
     */
    function tryCalcLPTokenUnderlying(
        IMultiFlowPumpWellFunction wf,
        uint256 lpTokenAmount,
        uint256[] memory reserves,
        uint256 lpTokenSupply,
        bytes memory data
    ) internal view returns (uint256[] memory underlyingAmounts) {
        return wf.calcLPTokenUnderlying(lpTokenAmount, reserves, lpTokenSupply, data);
        // try wf.calcLPTokenUnderlying(lpTokenAmount, reserves, lpTokenSupply, data) returns (uint256[] memory _underlyingAmounts) {
        //     underlyingAmounts = _underlyingAmounts;
        // } catch {
        //     underlyingAmounts = new uint256[](reserves.length);
        //     for (uint256 i; i < reserves.length; ++i) {
        //         underlyingAmounts[i] = type(uint256).max;
        //     }
        // }
    }
}
