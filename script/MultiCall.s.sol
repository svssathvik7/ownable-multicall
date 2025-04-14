// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MultiCall} from "../src/MultiCall.sol";

contract MultiCallScript is Script {
    MultiCall public multicall;
    uint256 public constant MAX_CALLS = 10000; // Maximum number of calls allowed in a single transaction

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy MultiCall contract with MAX_CALLS limit
        multicall = new MultiCall(MAX_CALLS);

        // Log deployment information
        console.log("MultiCall deployed to:", address(multicall));
        console.log("Deployer address:", multicall.deployer());
        console.log("Max calls limit:", multicall.maxCalls());

        vm.stopBroadcast();
    }
}
