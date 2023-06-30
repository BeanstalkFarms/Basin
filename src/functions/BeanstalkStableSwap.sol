// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "src/functions/StableSwap2.sol";
import {IBeanstalkA} from "src/interfaces/beanstalk/IBeanstalkA.sol";
import {IBeanstalkWellFunction} from "src/interfaces/IBeanstalkWellFunction.sol";


/**
 * @author Brean
 * @title Beanstalk Stableswap well function. Includes functions needed for the well 
 * to interact with the Beanstalk contract.
 * 
 * @dev The A parameter is an dynamic parameter, queried from the Beanstalk contract.
 * With an fallback A value determined by the well data.
 */
contract BeanstalkStableSwap is StableSwap2, IBeanstalkWellFunction {
    using LibMath for uint;
    using SafeMath for uint;

    // Beanstalk
    IBeanstalkA BEANSTALK = IBeanstalkA(0xC1E088fC1323b20BCBee9bd1B9fC9546db5624C5);
    uint256 PRECISION = 1e18;

    /**
     * TODO: for deltaB minting
     * `ratios` here refer to the virtual price of the non-bean asset.
     * (precision 1e18).
     */
    function calcReserveAtRatioSwap(
        uint256[] calldata reserves,
        uint256 j,
        uint256[] calldata ratios,
        bytes calldata data
    ) external view returns (uint256 reserve){
        uint256[] memory _reserves = new uint256[](2);
        _reserves[0] = reserves[0].mul(ratios[0]).div(PRECISION);
        _reserves[1] = reserves[1].mul(ratios[1]).div(PRECISION);
        // uint256 oldD = calcLpTokenSupply(reserves, data) / 2;
        uint256 newD = calcLpTokenSupply(_reserves, data);
        return newD / 2;
    }

    // TODO: for converts 
    // `ratios` here refer to the virtual price of the non-bean asset 
    // high level: calc the reserve via adding or removing liq given some reserves, to target ratio.
    // 
    function calcReserveAtRatioLiquidity(
        uint256[] calldata reserves,
        uint256 j,
        uint256[] calldata ratios,
        bytes calldata
    ) external pure returns (uint256 reserve){
        uint256 i = j == 1 ? 0 : 1;
        reserve = reserves[i] * ratios[j] / ratios[i];
    }

    function getBeanstalkA() public pure returns (uint256 a) {
        return IBeanstalkA(0xC1E088fC1323b20BCBee9bd1B9fC9546db5624C5).getBeanstalkA();
    }
    function getBeanstalkAnn() public pure returns (uint256 a) {
        return getBeanstalkA() * N * N;
    }

    // TODO: implement. 
    function getVirtualPrice() public pure returns (uint256 price) {
        price = 1.01 * 1e18;
    }

    function decodeWFData(
        bytes memory data
    ) public view override returns (
        uint256 Ann,
        uint256[2] memory precisionMultipliers
    ){
        WellFunctionData memory wfd = abi.decode(data, (WellFunctionData));
        
        // try to get the beanstalk A. 
        // if it fails, use the failsafe A stored in well function data.
        uint256 a;
        try BEANSTALK.getBeanstalkA() returns (uint256 _a) {
            a = _a;
        } catch  {
            a = wfd.a;
        }
        if(wfd.tkn0 == address(0) || wfd.tkn1 == address(0)) revert InvalidTokens();
        uint8 token0Dec = IERC20(wfd.tkn0).decimals();
        uint8 token1Dec = IERC20(wfd.tkn0).decimals();

        if(token0Dec > 18) revert InvalidTokenDecimals(token0Dec); 
        if(token1Dec > 18) revert InvalidTokenDecimals(token1Dec); 

        Ann = a * N * N * A_PRECISION;
        precisionMultipliers[0] = 10 ** (POOL_PRECISION_DECIMALS - uint256(token0Dec));
        precisionMultipliers[1] = 10 ** (POOL_PRECISION_DECIMALS - uint256(token0Dec));
    }

}
