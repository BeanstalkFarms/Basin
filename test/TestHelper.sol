pragma solidity ^0.8.17;

import "forge-std/console2.sol";
import "forge-std/console.sol";
import "forge-std/Test.sol";

import "oz/utils/Strings.sol";

import "src/Well.sol";
import "src/WellBuilder.sol";
import "src/functions/ConstantProduct2.sol";

import "mocks/tokens/MockToken.sol";
import "utils/Users.sol";

abstract contract TestHelper is Test {
    address user;
    IERC20[] tokens;
    WellBuilder wellBuilder;
    Well well;
    WellInfo w;

    using Strings for uint256;

    function setupWell(uint n) internal {
        initUser();
        deployMockTokens(n);
        wellBuilder = new WellBuilder();
        deployWell();
        mintTokens(address(this), 1000 * 1e18);
        approveMaxTokens(address(this), address(well));
        mintTokens(user, 1000 * 1e18);
        approveMaxTokens(user, address(well));
        addLiquidtyEqualAmount(address(this), 1000 * 1e18);
    }

    function initUser() internal {
        Users users = new Users();
        user = users.getNextUserAddress();
    }

    function deployMockTokens(uint n) internal {
        for (uint i = 0; i < n; i++) {
            tokens.push(IERC20(
                    new MockToken(
                        string.concat("Token ", i.toString()),
                        string.concat("TOKEN", i.toString()),
                        18
                    )
            ));
        }
    }

    function mintTokens(address recipient, uint amount) internal {
        for (uint i = 0; i < tokens.length; i++) MockToken(address(tokens[i])).mint(recipient, amount);
    }

    function approveMaxTokens(address owner, address spender) internal {
        vm.startPrank(owner);
        for (uint i = 0; i < tokens.length; i++) tokens[i].approve(spender, type(uint256).max);
        vm.stopPrank();
    }

    function deployWell() internal returns (Well) {
        ConstantProduct2 constantProduct = new ConstantProduct2();
        // well = new Well();
        w.wellFunction = Call(address(constantProduct), new bytes(0));
        w.tokens = tokens;
        // well.initialize(w);
        well = Well(wellBuilder.buildWell(w));
        return well;
    }

    function addLiquidtyEqualAmount(address from, uint amount) internal {
        vm.startPrank(from);
        uint[] memory amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) amounts[i] = amount;
        well.addLiquidity(w, amounts, 0, from);
        vm.stopPrank();
    }

    modifier prank(address from) {
        vm.startPrank(from);
        _;
        vm.stopPrank();
    }
}