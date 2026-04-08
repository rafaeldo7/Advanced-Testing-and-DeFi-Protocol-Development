// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Token.sol";
import "../src/AMM.sol";

/**
 * @title DeployScript
 * @dev Deployment script for AMM
 */
contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Token A
        Token tokenA = new Token(
            "Token A",
            "TKNA",
            18,
            1_000_000 * 1e18,
            msg.sender
        );

        // Deploy Token B
        Token tokenB = new Token(
            "Token B", 
            "TKNB",
            18,
            1_000_000 * 1e18,
            msg.sender
        );

        // Deploy AMM
        AMM amm = new AMM(
            address(tokenA),
            address(tokenB),
            msg.sender
        );

        console.log("Token A deployed:", address(tokenA));
        console.log("Token B deployed:", address(tokenB));
        console.log("AMM deployed:", address(amm));

        vm.stopBroadcast();
    }
}
