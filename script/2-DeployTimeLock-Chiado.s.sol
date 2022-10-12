// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract DeployTimeLock is Script {
    uint256 public constant MIN_DELAY = 3600; // 1 hour
    address[] proposers; // We want to keep this array empty for now
    address[] executors; // We want to keep this array empty for now

    // We basically want only the GovernorContract to be able to propose anything and then anyone can 
    // execute the proposal (after the MIN_DELAY)

    TimeLock timeLock;
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("CHIADO_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        {
            timeLock = new TimeLock(
                MIN_DELAY,
                proposers, //List of proposers
                executors // List of executors
            );
        }
        vm.stopBroadcast();
    }
}