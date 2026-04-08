// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Token
 * @dev Simple ERC-20 token with mint, burn, and Ownable functionality
 */
contract Token is ERC20, ERC20Burnable, Ownable {
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name}, {symbol}, and {decimals}.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply,
        address initialOwner
    ) ERC20(name_, symbol_) Ownable(initialOwner) {
        _decimals = decimals_;
        if (initialSupply > 0) {
            _mint(initialOwner, initialSupply * 10 ** decimals_);
        }
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing the total supply.
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * Emits a {Transfer} event with `to` set to the zero address.
     */
    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
}
