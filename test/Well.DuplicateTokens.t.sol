// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {console, Aquifer, IERC20, TestHelper} from "test/TestHelper.sol";
import {LibWellConstructor} from "src/libraries/LibWellConstructor.sol";
import {IWell} from "src/interfaces/IWell.sol";

contract WellDuplicateTokens is TestHelper {
    function test_fail_on_duplicate_tokens() public {
        tokens = new IERC20[](2);
        tokens[0] = deployMockToken(0);
        tokens[1] = tokens[0];
        initUser();
        wellImplementation = deployWellImplementation();
        wellFunction = deployWellFunction();
        aquifer = new Aquifer();
        (bytes memory immutableData, bytes memory initData) =
            LibWellConstructor.encodeWellDeploymentData(address(aquifer), tokens, wellFunction, pumps);

        vm.expectRevert(abi.encodeWithSelector(Aquifer.InitFailed.selector, ""));
        Aquifer(aquifer).boreWell(wellImplementation, immutableData, initData, bytes32(0));
    }
}
