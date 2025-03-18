//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {HonkVerifier} from "thaler_circuits/target/contract.sol";

contract DeployHonkVerifier is Script {
    HonkVerifier public honk;

    function run() public {
        vm.startBroadcast();
        honk = new HonkVerifier();
        vm.stopBroadcast();
    }
}
