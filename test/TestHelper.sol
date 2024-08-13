// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console, stdError} from "forge-std/Test.sol";
import {Strings} from "oz/utils/Strings.sol";

import {MockToken} from "mocks/tokens/MockToken.sol";
import {MockTokenFeeOnTransfer} from "mocks/tokens/MockTokenFeeOnTransfer.sol";
import {MockPump} from "mocks/pumps/MockPump.sol";

import {Users} from "test/helpers/Users.sol";

import {Well, Call, IERC20, IWell, IWellFunction} from "src/Well.sol";
import {Aquifer} from "src/Aquifer.sol";
import {ConstantProduct2} from "src/functions/ConstantProduct2.sol";
import {Stable2} from "src/functions/Stable2.sol";
import {Stable2LUT1} from "src/functions/StableLUT/Stable2LUT1.sol";

import {WellDeployer} from "script/helpers/WellDeployer.sol";

import {Math} from "oz/utils/math/Math.sol";
import {stdMath} from "forge-std/StdMath.sol";

/// @dev Helper struct for quickly loading user / well token balances
struct Balances {
    /// Address balance of each token in the Well
    uint256[] tokens;
    /// Address balance of LP tokens
    uint256 lp;
    /// Total LP token supply for the relevant Well
    uint256 lpSupply;
}

/**
 * @dev Holds a snapshot of User & Well balances. Used to calculate the change
 * in balanace across some action in the Well.
 */
struct Snapshot {
    Balances user;
    Balances well;
    uint256[] reserves;
}

abstract contract TestHelper is Test, WellDeployer {
    using Math for uint256;
    using Strings for uint256;

    // Errors are mirrored from IWell
    error SlippageOut(uint256 amountOut, uint256 minAmountOut);
    error Expired();

    // Users
    Users users;
    address user;
    address user2;

    // Primary well
    Well well;
    address wellImplementation;

    // Primary well components
    IERC20[] tokens;
    Call wellFunction;
    Call[] pumps;
    bytes[] pumpData;
    bytes wellData;

    // Registry
    Aquifer aquifer;

    // Initial liquidity amount given to users and wells
    uint256 public constant initialLiquidity = 1000 * 1e18;

    function setupWell(uint256 n) internal {
        setupWell(n, deployWellFunction(), deployPumps(1));
    }

    function setupWell(uint256 n, Call[] memory _pumps) internal {
        setupWell(n, deployWellFunction(), _pumps);
    }

    function setupWell(uint256 n, Call memory _wellFunction, Call[] memory _pumps) internal {
        setupWell(_wellFunction, _pumps, deployMockTokens(n));
    }

    function setupWell(Call memory _wellFunction, Call[] memory _pumps, IERC20[] memory _tokens) internal {
        tokens = _tokens;
        wellFunction = _wellFunction;
        for (uint256 i; i < _pumps.length; i++) {
            pumps.push(_pumps[i]);
        }

        initUser();

        wellImplementation = deployWellImplementation();
        aquifer = new Aquifer();
        well = encodeAndBoreWell(address(aquifer), wellImplementation, tokens, _wellFunction, _pumps, bytes32(0));

        // Mint mock tokens to user
        mintTokens(user, initialLiquidity);
        mintTokens(user2, initialLiquidity);
        approveMaxTokens(user, address(well));
        approveMaxTokens(user2, address(well));

        // Mint mock tokens to TestHelper
        mintTokens(address(this), initialLiquidity);
        approveMaxTokens(address(this), address(well));

        // Add initial liquidity from TestHelper
        addLiquidityEqualAmount(address(this), initialLiquidity);
    }

    function setupWellWithFeeOnTransfer(uint256 n) internal {
        Call memory _wellFunction = Call(address(new ConstantProduct2()), new bytes(0));
        Call[] memory _pumps = new Call[](2);
        _pumps[0].target = address(new MockPump());
        _pumps[0].data = new bytes(1);
        _pumps[1].target = address(new MockPump());
        _pumps[1].data = new bytes(1);
        setupWell(_wellFunction, _pumps, deployMockTokensFeeOnTransfer(n));
    }

    function initUser() internal {
        users = new Users();
        address[] memory _user = new address[](2);
        _user = users.createUsers(2);
        user = _user[0];
        user2 = _user[1];
    }

    function setupStable2Well() internal {
        setupStable2Well(deployPumps(1), deployMockTokens(2));
    }

    function setupStable2Well(Call[] memory _pumps, IERC20[] memory _tokens) internal {
        // deploy new LUT:
        address lut = address(new Stable2LUT1());
        // encode wellFunction Data
        bytes memory wellFunctionData =
            abi.encode(MockToken(address(_tokens[0])).decimals(), MockToken(address(_tokens[1])).decimals());
        Call memory _wellFunction = Call(address(new Stable2(lut)), wellFunctionData);
        tokens = _tokens;
        wellFunction = _wellFunction;
        vm.label(address(wellFunction.target), "Stable2 WF");
        for (uint256 i = 0; i < _pumps.length; i++) {
            pumps.push(_pumps[i]);
        }

        initUser();

        wellImplementation = deployWellImplementation();
        aquifer = new Aquifer();
        well = encodeAndBoreWell(address(aquifer), wellImplementation, tokens, _wellFunction, _pumps, bytes32(0));
        vm.label(address(well), "Stable2Well");

        // Mint mock tokens to user
        mintTokens(user, initialLiquidity);
        mintTokens(user2, initialLiquidity);
        approveMaxTokens(user, address(well));
        approveMaxTokens(user2, address(well));

        // Mint mock tokens to TestHelper
        mintTokens(address(this), initialLiquidity);
        approveMaxTokens(address(this), address(well));

        // Add initial liquidity from TestHelper
        addLiquidityEqualAmount(address(this), initialLiquidity);
    }

    //////////// Test Tokens ////////////

    /// @dev deploy `n` mock ERC20 tokens and sort by address
    function deployMockTokens(uint256 n) internal returns (IERC20[] memory _tokens) {
        _tokens = new IERC20[](n);
        for (uint256 i; i < n; i++) {
            _tokens[i] = deployMockToken(i);
        }
    }

    function deployMockToken(uint256 i) internal returns (IERC20) {
        return IERC20(
            new MockToken(
                string.concat("Token ", i.toString()), // name
                string.concat("TOKEN", i.toString()), // symbol
                18 // decimals
            )
        );
    }

    function deployMockTokenWithDecimals(uint256 i, uint8 decimals) internal returns (IERC20) {
        return IERC20(
            new MockToken(
                string.concat("Token ", i.toString()), // name
                string.concat("TOKEN", i.toString()), // symbol
                decimals // decimals
            )
        );
    }

    /// @dev deploy `n` mock ERC20 tokens and sort by address
    function deployMockTokensFeeOnTransfer(uint256 n) internal returns (IERC20[] memory _tokens) {
        _tokens = new IERC20[](n);
        for (uint256 i; i < n; i++) {
            _tokens[i] = deployMockTokenFeeOnTransfer(i);
        }
    }

    function deployMockTokenFeeOnTransfer(uint256 i) internal returns (IERC20) {
        return IERC20(
            new MockTokenFeeOnTransfer(
                string.concat("Token ", i.toString()), // name
                string.concat("TOKEN", i.toString()), // symbol
                18 // decimals
            )
        );
    }

    /// @dev mint mock tokens to each recipient
    function mintTokens(address recipient, uint256 amount) internal {
        for (uint256 i; i < tokens.length; i++) {
            MockToken(address(tokens[i])).mint(recipient, amount);
        }
    }

    /// @dev mint mock tokens to each recipient in different amounts
    function mintTokens(address recipient, uint256[] memory amounts) internal {
        for (uint256 i; i < tokens.length; i++) {
            MockToken(address(tokens[i])).mint(recipient, amounts[i]);
        }
    }

    /// @dev approve `spender` to use `owner` tokens
    function approveMaxTokens(address owner, address spender) internal prank(owner) {
        for (uint256 i; i < tokens.length; i++) {
            tokens[i].approve(spender, type(uint256).max);
        }
    }

    /// @dev gets the first `n` mock tokens
    function getTokens(uint256 n) internal view returns (IERC20[] memory _tokens) {
        _tokens = new IERC20[](n);
        for (uint256 i; i < n; ++i) {
            _tokens[i] = tokens[i];
        }
    }

    //////////// Well Setup ////////////

    function deployWellFunction() internal returns (Call memory _wellFunction) {
        _wellFunction.target = address(new ConstantProduct2());
        _wellFunction.data = new bytes(0);
    }

    function deployWellFunction(address _target) internal pure returns (Call memory _wellFunction) {
        _wellFunction.target = _target;
        _wellFunction.data = new bytes(0);
    }

    function deployWellFunction(
        address _target,
        bytes memory _data
    ) internal pure returns (Call memory _wellFunction) {
        _wellFunction.target = _target;
        _wellFunction.data = _data;
    }

    function deployPumps(uint256 n) internal returns (Call[] memory _pumps) {
        _pumps = new Call[](n);
        for (uint256 i; i < n; i++) {
            _pumps[i].target = address(new MockPump());
            _pumps[i].data = new bytes(0);
        }
    }

    /// @dev deploy the Well contract
    function deployWellImplementation() internal returns (address) {
        return address(new Well());
    }

    function mintAndAddLiquidity(address to, uint256[] memory amounts) internal {
        mintTokens(user, amounts);
        well.addLiquidity(amounts, 0, to, type(uint256).max);
    }

    /// @dev add the same `amount` of liquidity for all underlying tokens
    function addLiquidityEqualAmount(address from, uint256 amount) internal prank(from) {
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            amounts[i] = amount;
        }
        well.addLiquidity(amounts, 0, from, type(uint256).max);
    }

    //////////// Balance Helpers ////////////

    /// @dev get `account` balance of each token, lp token, total lp token supply
    /// @dev uses global tokens but not global well
    function getBalances(address account, Well _well) internal view returns (Balances memory balances) {
        uint256[] memory tokenBalances = new uint256[](tokens.length);
        for (uint256 i; i < tokenBalances.length; ++i) {
            tokenBalances[i] = tokens[i].balanceOf(account);
        }
        balances.tokens = tokenBalances;
        balances.lp = _well.balanceOf(account);
        balances.lpSupply = _well.totalSupply();
    }

    //////////// EVM Helpers ////////////

    function increaseTime(uint256 _seconds) internal {
        vm.warp(block.timestamp + _seconds);
    }

    modifier prank(address from) {
        vm.startPrank(from);
        _;
        vm.stopPrank();
    }

    //////////// Assertions ////////////

    function assertEq(IERC20 a, IERC20 b) internal pure {
        assertEq(a, b, "Address mismatch");
    }

    function assertEq(IERC20 a, IERC20 b, string memory err) internal pure {
        assertEq(address(a), address(b), err);
    }

    function assertEq(IERC20[] memory a, IERC20[] memory b) internal pure {
        assertEq(a, b, "IERC20[] mismatch");
    }

    function assertEq(IERC20[] memory a, IERC20[] memory b, string memory err) internal pure {
        assertEq(a.length, b.length, err);
        for (uint256 i; i < a.length; i++) {
            assertEq(a[i], b[i], err); // uses the prev overload
        }
    }

    function assertEq(Call memory a, Call memory b) internal pure {
        assertEq(a, b, "Call mismatch");
    }

    function assertEq(Call memory a, Call memory b, string memory err) internal pure {
        assertEq(a.target, b.target, err);
        assertEq(a.data, b.data, err);
    }

    function assertEq(Call[] memory a, Call[] memory b) internal pure {
        assertEq(a, b, "Call[] mismatch");
    }

    function assertEq(Call[] memory a, Call[] memory b, string memory err) internal pure {
        assertEq(a.length, b.length, err);
        for (uint256 i; i < a.length; i++) {
            assertEq(a[i], b[i], err); // uses the prev overload
        }
    }

    function assertApproxEqRelN(uint256 a, uint256 b, uint256 precision) internal virtual {
        assertApproxEqRelN(a, b, 1, precision);
    }

    function assertApproxLeRelN(uint256 a, uint256 b, uint256 precision, uint256 absoluteError) internal pure {
        console.log("A: %s", a);
        console.log("B: %s", b);
        console.log(precision);
        uint256 numDigitsA = numDigits(a);
        uint256 numDigitsB = numDigits(b);
        if (numDigitsA != numDigitsB || numDigitsA < precision) {
            if (b + absoluteError < type(uint256).max) {
                assertLe(a, b + absoluteError);
            }
        } else {
            uint256 denom = 10 ** (numDigits(a) - precision);
            uint256 maxB = b / denom;
            console.log("Max B", maxB);
            console.log("Max B", maxB + absoluteError);
            if (maxB + absoluteError < type(uint256).max) {
                assertLe(a / denom, maxB + absoluteError);
            }
        }
    }

    function assertApproxGeRelN(uint256 a, uint256 b, uint256 precision, uint256 absoluteError) internal pure {
        console.log("A: %s", a);
        console.log("B: %s", b);
        console.log(precision);
        uint256 numDigitsA = numDigits(a);
        uint256 numDigitsB = numDigits(b);
        if (numDigitsA != numDigitsB || numDigitsA < precision) {
            console.log("Here for some reason");
            if (b > absoluteError) {
                assertGe(a, b - absoluteError);
            }
        } else {
            uint256 denom = 10 ** (numDigits(a) - precision);
            uint256 minB = b / denom;
            console.log("Min B: %s, Abs Err: %s", minB, absoluteError);
            if (minB > absoluteError) {
                assertGe(a / denom, minB - absoluteError);
            }
        }
    }

    function assertApproxEqRelN(
        uint256 a,
        uint256 b,
        uint256 maxPercentDelta, // An 18 decimal fixed point number, where 1e18 == 100%
        uint256 precision
    ) internal virtual {
        if (b == 0) return assertEq(a, b); // If the expected is 0, actual must be too.

        uint256 percentDelta = percentDeltaN(a, b, precision);

        if (percentDelta > maxPercentDelta) {
            emit log("Error: a ~= b not satisfied [uint]");
            emit log_named_uint("    Expected", b);
            emit log_named_uint("      Actual", a);
            emit log_named_decimal_uint(" Max % Delta", maxPercentDelta, precision);
            emit log_named_decimal_uint("     % Delta", percentDelta, precision);
            fail();
        }
    }

    function percentDeltaN(uint256 a, uint256 b, uint256 precision) internal pure returns (uint256) {
        uint256 absDelta = stdMath.delta(a, b);

        return (absDelta * (10 ** precision)) / b;
    }

    function _newSnapshot() internal view returns (Snapshot memory snapshot) {
        snapshot.user = getBalances(user, well);
        snapshot.well = getBalances(address(well), well);
        snapshot.reserves = well.getReserves();
    }

    function checkInvariant(address _well) internal view {
        uint256[] memory _reserves = IWell(_well).getReserves();
        Call memory _wellFunction = IWell(_well).wellFunction();
        assertLe(
            IERC20(_well).totalSupply(),
            IWellFunction(_wellFunction.target).calcLpTokenSupply(_reserves, _wellFunction.data),
            "totalSupply() is greater than calcLpTokenSupply()"
        );
    }

    function checkStableSwapInvariant(address _well) internal view {
        uint256[] memory _reserves = IWell(_well).getReserves();
        Call memory _wellFunction = IWell(_well).wellFunction();
        assertApproxEqAbs(
            IERC20(_well).totalSupply(),
            IWellFunction(_wellFunction.target).calcLpTokenSupply(_reserves, _wellFunction.data),
            2
        );
    }

    function getPrecisionForReserves(uint256[] memory reserves) internal pure returns (uint256 precision) {
        precision = type(uint256).max;
        for (uint256 i; i < reserves.length; ++i) {
            uint256 logReserve = reserves[i].log10();
            if (logReserve < precision) precision = logReserve;
        }
    }

    function uint2ToUintN(uint256[2] memory input) internal pure returns (uint256[] memory out) {
        out = new uint256[](input.length);
        for (uint256 i; i < input.length; i++) {
            out[i] = input[i];
        }
    }

    function numDigits(uint256 number) internal pure returns (uint256 digits) {
        while (number > 9) {
            number /= 10;
            digits++;
        }
    }
}
