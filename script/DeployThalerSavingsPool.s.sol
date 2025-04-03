//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

import {ThalerSavingsPool} from "src/ThalerSavingsPool.sol";

contract DeployThalerSavingsPool is Script {
    ThalerSavingsPool public savingsPool;

    function run() public {
        vm.startBroadcast();
        savingsPool = new ThalerSavingsPool();
        vm.stopBroadcast();
    }
}
