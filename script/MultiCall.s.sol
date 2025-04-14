// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MultiCall} from "../src/MultiCall.sol";

contract CounterScript is Script {
    MultiCall public counter;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        counter = new MultiCall();

        vm.stopBroadcast();
    }
}
