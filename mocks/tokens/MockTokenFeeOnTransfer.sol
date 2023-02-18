/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;

import "oz/token/ERC20/extensions/ERC20Burnable.sol";
import "oz/token/ERC20/extensions/draft-ERC20Permit.sol";

/**
 * @author Publius
 * @title Mock Token with a Fee on transfer
 */
contract MockTokenFeeOnTransfer is ERC20Burnable, ERC20Permit {

    uint8 private _decimals = 18;
    mapping(address => uint256) private _balances;

    uint constant FEE_DIVISOR = 1e18;

    uint public fee = 0;

    constructor(string memory name, string memory symbol, uint8 __decimals)
        ERC20(name, symbol)
        ERC20Permit(name)
    {
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

    function setFee(uint _fee) external {
        fee = _fee;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        uint _fee = amount * fee / FEE_DIVISOR;
        uint amountSent = amount - _fee;

        _spendAllowance(from, spender, amount);
        _transfer(from, to, amountSent);
        _burn(from, _fee);

        return true;
    }
}