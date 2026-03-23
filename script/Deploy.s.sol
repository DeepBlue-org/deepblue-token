// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../DeepBlueToken.sol";

contract DeployToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy with 1B supply, all minted to deployer
        DeepBlueToken token = new DeepBlueToken(
            "DeepBlue",        // name — change as needed
            "DEEP",            // symbol — change as needed
            1_000_000_000 * 1e18  // initial mint: full 1B supply to deployer
        );

        console.log("Token deployed at:", address(token));

        vm.stopBroadcast();
    }
}
