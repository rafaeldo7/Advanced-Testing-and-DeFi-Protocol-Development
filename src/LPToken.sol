// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Token.sol";

/**
 * @title LPToken
 * @notice ERC-20 token representing liquidity provider shares in the AMM
 */
contract LPToken is ERC20 {
    address public amm;

    modifier onlyAMM() {
        require(msg.sender == amm, "Only AMM can mint/burn");
        _;
    }

    constructor() ERC20("Liquidity Provider Token", "LP") {
        amm = msg.sender;
    }

    function mint(address to, uint256 amount) external override onlyAMM {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external override onlyAMM {
        _burn(from, amount);
    }
}
