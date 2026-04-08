// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Token.sol";

/**
 * @title TokenA
 * @notice Test token for AMM pair
 */
contract TokenA is ERC20 {
    constructor(uint256 initialSupply) ERC20("Token A", "TKNA") {
        _mint(msg.sender, initialSupply);
    }
}
