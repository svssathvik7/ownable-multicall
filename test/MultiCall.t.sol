// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MultiCall} from "../src/MultiCall.sol";

contract MultiCallTest is Test {
    MultiCall public multicall;
    address public deployingUser;

    function setUp() public {
        deployingUser = address(1);
        vm.prank(deployingUser);
        multicall = new MultiCall(10000);
    }

    function test_deployer() public view {
        assertEq(multicall.deployer(), deployingUser, "Error setting deployer");
    }
}
