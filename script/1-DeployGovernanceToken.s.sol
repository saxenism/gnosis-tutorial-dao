// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";

contract DeployGovernaneToken is Script {
    GovernanceToken governanceToken;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        {
            governanceToken = new GovernanceToken();
        }
        vm.stopBroadcast();

        console2.log("Governance Token deployed.");
        console2.log("Governance Token deployed at: ", address(governanceToken));

        vm.startBroadcast(deployerPrivateKey);
        {
            governanceToken.delegate(msg.sender);
            uint256 checkpoint = governanceToken.numCheckpoints(msg.sender);
            console2.log("Checkpoint: ", checkpoint);
            assert(checkpoint != 0);
        }
        vm.stopBroadcast();
    }
}
