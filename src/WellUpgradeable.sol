// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Well} from "src/Well.sol";
import {UUPSUpgradeable} from "ozu/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "ozu/access/OwnableUpgradeable.sol";
import {IERC20, SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";
import {IAquifer} from "src/interfaces/IAquifer.sol";
/**
 * @title Well
 * @author Publius, Silo Chad, Brean, Deadmanwalking
 * @dev A Well is a constant function AMM allowing the provisioning of liquidity
 * into a single pooled on-chain liquidity position.
 *
 * Rebasing Tokens:
 * - Positive rebasing tokens are supported by Wells, but any tokens recieved from a
 *   rebase will not be rewarded to LP holders and instead can be extracted by anyone
 *   using `skim`, `sync` or `shift`.
 * - Negative rebasing tokens should not be used in Well as the effect of a negative
 *   rebase will be realized by users interacting with the Well, not LP token holders.
 *
 * Fee on Tranfer (FoT) Tokens:
 * - When transferring fee on transfer tokens to a Well (swapping from or adding liquidity),
 *   use `swapFromFeeOnTrasfer` or `addLiquidityFeeOnTransfer`. `swapTo` does not support
 *   fee on transfer tokens (See {swapTo}).
 * - When recieving fee on transfer tokens from a Well (swapping to and removing liquidity),
 *   INCLUDE the fee that is taken on transfer when calculating amount out values.
 */
contract WellUpgradeable is Well, UUPSUpgradeable, OwnableUpgradeable  {

    address private immutable ___self = address(this);

    function init(string memory _name, string memory _symbol, address owner) external initializer {
        // owner of well param as the aquifier address will be the owner initially
        // ownable init transfers ownership to msg.sender
        __ERC20Permit_init(_name);
        __ERC20_init(_name, _symbol);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        // first time this is called the owner will be the msg.sender
        // which is the aquifer that bore the well
        __Ownable_init();
        // then ownership can be transfered to the wanted address 
        // note: to init owner with __Ownable_init(ownerAddress); we would need to adjust the lib code
        transferOwnership(owner);

        IERC20[] memory _tokens = tokens();
        uint256 tokensLength = _tokens.length;
        for (uint256 i; i < tokensLength - 1; ++i) {
            for (uint256 j = i + 1; j < tokensLength; ++j) {
                if (_tokens[i] == _tokens[j]) {
                    revert DuplicateTokens(_tokens[i]);
                }
            }
        }
    }
    
    function getVersion() external virtual pure returns (uint256) {
        return 1;
    }

    // Wells deployed by aquifers use the EIP-1167 minimal proxy pattern for gas-efficent deployments.
    // This pattern breaks the UUPS upgrade pattern, as the `__self` variable is set to the initial well implmentation.
    // `_authorizeUpgrade` and `upgradeTo` are modified to allow for upgrades to the Well implementation.
    // verification is done by verifying the ERC1967 implmentation (the well address) maps to the aquifers well -> implmentation mapping.

    /**
     * @notice Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an ERC1167 minimal proxy from an aquifier, pointing to a well implmentation.
     */
    function _authorizeUpgrade(address newImplmentation) internal view override {
        // verify the function is called through a delegatecall.
        require(address(this) != ___self, "Function must be called through delegatecall");

        // verify the function is called through an active proxy bored by an aquifer.
        address activeProxy = IAquifer(aquifer()).wellImplementation(_getImplementation());
        require(activeProxy == ___self, "Function must be called through active proxy bored by an aquifer");

        // verify the new implmentation is a well bored by an aquifier.
        address aquifer = Well(newImplmentation).aquifer();
        require(
            IAquifer(aquifer).wellImplementation(newImplmentation) != address(0),
            "New implementation must be a well implmentation"
        );

        // verify the new implmentation is a valid ERC-1967 implmentation.
        require(
            UUPSUpgradeable(newImplmentation).proxiableUUID() == _IMPLEMENTATION_SLOT, 
            "New implementation must be a valid ERC-1967 implmentation"
        );
    }

    /**
     * @notice Upgrade the implementation of the proxy to `newImplementation`.
     * @dev replaces 'onlyProxy' with `_authorizeUpgrade` restriction.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     * 
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public override {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @notice Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable override {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }
}