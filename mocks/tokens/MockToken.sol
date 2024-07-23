/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.20;

import "oz/token/ERC20/extensions/ERC20Burnable.sol";
import "oz/token/ERC20/extensions/draft-ERC20Permit.sol";

/**
 * @author Brendan
 * @title Mock Token
 */
contract MockToken is ERC20Burnable, ERC20Permit {
    uint8 private _decimals = 18;

    constructor(string memory name, string memory symbol, uint8 __decimals) ERC20(name, symbol) ERC20Permit(name) {
        _decimals = __decimals;
    }

    function mint(address account, uint256 amount) external returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burnFrom(address account, uint256 amount) public override(ERC20Burnable) {
        ERC20Burnable.burnFrom(account, amount);
    }

    function burn(uint256 amount) public override(ERC20Burnable) {
        ERC20Burnable.burn(amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
