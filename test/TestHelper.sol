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
    Call pump;
    Call wellFunction;
    WellBuilder wellBuilder;
    Well well;

    using Strings for uint256;

    function setupWell(uint256 n) internal {
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

    function deployMockTokens(uint256 n) internal {
        IERC20[] memory _tokens = new IERC20[](n);
        console2.log(n);
        for (uint256 i = 0; i < n; i++) {
            IERC20 temp = IERC20(
                new MockToken(
                    string.concat("Token ", i.toString()),
                    string.concat("TOKEN", i.toString()),
                    18
                )
            );
            uint256 j;
            if (i > 0) {
                for (j = i; j >= 1 && temp < _tokens[j - 1]; j--)
                    _tokens[j] = _tokens[j - 1];
                _tokens[j] = temp;
            } else _tokens[0] = temp;
        }
        for (uint256 i = 0; i < n; i++) tokens.push(_tokens[i]);
    }

    function mintTokens(address recipient, uint256 amount) internal {
        for (uint256 i = 0; i < tokens.length; i++)
            MockToken(address(tokens[i])).mint(recipient, amount);
    }

    function approveMaxTokens(address owner, address spender) internal {
        vm.startPrank(owner);
        for (uint256 i = 0; i < tokens.length; i++)
            tokens[i].approve(spender, type(uint256).max);
        vm.stopPrank();
    }

    function deployWell() internal returns (Well) {
        wellFunction = Call(address(new ConstantProduct2()), new bytes(0));
        well = Well(wellBuilder.buildWell(tokens, wellFunction, pump));
        return well;
    }

    function addLiquidtyEqualAmount(address from, uint256 amount) internal {
        vm.startPrank(from);
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) amounts[i] = amount;
        well.addLiquidity(amounts, 0, from);
        vm.stopPrank();
    }

    modifier prank(address from) {
        vm.startPrank(from);
        _;
        vm.stopPrank();
    }

    function getTokens(uint256 n)
        internal
        view
        returns (IERC20[] memory _tokens)
    {
        _tokens = new IERC20[](n);
        for (uint256 i; i < n; ++i) {
            _tokens[i] = tokens[i];
        }
    }
}
