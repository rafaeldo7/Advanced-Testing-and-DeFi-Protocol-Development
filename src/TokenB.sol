// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Token.sol";

/**
 * @title TokenB
 * @notice Test token for AMM pair
 */
contract TokenB is ERC20 {
    constructor(uint256 initialSupply) ERC20("Token B", "TKNB") {
        _mint(msg.sender, initialSupply);
    }
}
