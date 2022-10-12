// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {GovernorContract} from "../src/GovernorContract.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";
import {TimeLock} from "../src/TimeLock.sol";

/**
export const QUORUM_PERCENTAGE = 4 // Need 4% of voters to pass
export const MIN_DELAY = 3600 // 1 hour - after a vote passes, you have 1 hour before you can enact
// export const VOTING_PERIOD = 45818 // 1 week - how long the vote lasts. This is pretty long even for local tests
export const VOTING_PERIOD = 5 // blocks
export const VOTING_DELAY = 1 // 1 Block - How many blocks till a proposal vote becomes active
*/

contract DeployGovernorContract is Script {
    GovernanceToken governanceToken = GovernanceToken(0x3b1223B91049644439e27E3aE1E324f428470533);
    TimeLock timeLock = TimeLock(payable(0x834bdCbaAe8b03FaBB1EEe03297fC1e5ee3D1bA8));

    GovernorContract governorContract;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("CHIADO_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        {
            governorContract = new GovernorContract(
                governanceToken,
                timeLock,
                1,
                5,
                4
            );
        }
        vm.stopBroadcast();
    }
}