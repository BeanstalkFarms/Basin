// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

import {Test} from "forge-std/Test.sol";

//common utilities for forge tests
contract Users is Test {
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    function getNextUserAddress() external returns (address) {
        //bytes32 to address conversion
        address user = address(uint160(uint256(nextUser)));
        nextUser = keccak256(abi.encodePacked(nextUser));
        vm.deal(user, 100 ether);
        return user;
    }

    //create users with 100 ether balance
    function createUsers(uint256 userNum) external returns (address[] memory) {
        address[] memory users = new address[](userNum);
        for (uint256 i; i < userNum; i++) {
            address user = this.getNextUserAddress();
            users[i] = user;
        }
        return users;
    }

    //move block.number forward by a given number of blocks
    function mineBlocks(uint256 numBlocks) external {
        uint256 targetBlock = block.number + numBlocks;
        vm.roll(targetBlock);
    }
}
