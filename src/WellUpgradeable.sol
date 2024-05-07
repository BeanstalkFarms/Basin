// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Well} from "src/Well.sol";
import {UUPSUpgradeable} from "ozu/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "ozu/access/OwnableUpgradeable.sol";
import {IERC20, SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";


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
    
    /**
    * Perform an upgrade of an ERC1967Proxy, when this contract.
    * is set as the implementation behind such a proxy.
    * The _authorizeUpgrade function must be overridden.
    * to include access restriction to the upgrade mechanism.
    */
    function _authorizeUpgrade(address) internal override onlyOwner {}

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
}