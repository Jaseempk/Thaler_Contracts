//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

import {ThalerSavingsPool} from "src/ThalerSavingsPool.sol";

contract DeployThalerSavingsPool is Script {
    ThalerSavingsPool public savingsPool;
    address verifier = 0xEA63d1094Ef863aa572e7A3584e4be3a34649422;

    function run() public {
        vm.startBroadcast();
        savingsPool = new ThalerSavingsPool(verifier);
        vm.stopBroadcast();
    }
}
