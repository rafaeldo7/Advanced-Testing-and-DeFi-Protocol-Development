// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/TokenA.sol";
import "../src/TokenB.sol";
import "../src/AMM.sol";
import "forge-std/Script.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy tokens
        TokenA tokenA = new TokenA(1000000e18);
        TokenB tokenB = new TokenB(1000000e18);

        // Deploy AMM
        AMM amm = new AMM(address(tokenA), address(tokenB));

        console.log("TokenA deployed at:", address(tokenA));
        console.log("TokenB deployed at:", address(tokenB));
        console.log("AMM deployed at:", address(amm));

        vm.stopBroadcast();
    }
}
