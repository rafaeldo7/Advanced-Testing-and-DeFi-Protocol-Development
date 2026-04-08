// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LPToken
 * @dev Liquidity Provider token for the AMM
 */
contract LPToken is ERC20, Ownable {
    address public amm;

    modifier onlyAMM() {
        require(msg.sender == amm, "LPToken: Only AMM can mint/burn");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address _owner
    ) ERC20(name_, symbol_) Ownable(_owner) {
        // Initially amm is zero - will be set by AMM
    }

    /**
     * @dev Mint LP tokens (only callable by AMM)
     */
    function mint(address to, uint256 amount) external onlyAMM {
        _mint(to, amount);
    }

    /**
     * @dev Burn LP tokens (only callable by AMM)
     */
    function burn(address from, uint256 amount) external onlyAMM {
        _burn(from, amount);
    }

    /**
     * @dev Set AMM address - can be called by anyone since LPToken is deployed by AMM
     */
    function setAMM(address _amm) external {
        require(_amm != address(0), "LPToken: Invalid AMM address");
        require(amm == address(0), "LPToken: AMM already set");
        amm = _amm;
    }
}
