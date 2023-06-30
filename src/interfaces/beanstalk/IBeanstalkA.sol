// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title IBeanstalkA
 * @author Brean
 * @notice Interface for the Beanstalk A, the A parameter that beanstalk sets.
 */
interface IBeanstalkA {
   
   /**
    * @return a A parameter, precision of 2 (a of 1 == 100)
    */
   function getBeanstalkA() external pure returns (uint256 a);
}
