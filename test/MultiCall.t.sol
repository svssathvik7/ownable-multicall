// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MultiCall} from "../src/MultiCall.sol";

contract MultiCallTest is Test {
    MultiCall public multicall;
    address public deployingUser;
    address public sathvik;
    uint256 public maxCalls = 10000;

    function setUp() public {
        deployingUser = address(1);
        vm.prank(deployingUser);
        multicall = new MultiCall(maxCalls);
    }

    function test_deployer() public view {
        assertEq(multicall.deployer(), deployingUser, "Error setting deployer");
    }

    function test_set_maxCalls() public {
        assertEq(multicall.maxCalls(), maxCalls, "Error setting maxCalls");
        vm.startPrank(deployingUser);
        multicall.changeMaxCalls(10);
        assertEq(multicall.maxCalls(), 10, "Error setting maxCalls");
        vm.stopPrank();
    }

    function test_set_maxCalls_not_deployer() public {
        vm.startPrank(sathvik);
        vm.expectRevert(abi.encodeWithSignature("NotAnOwner()"));
        multicall.changeMaxCalls(10);
        vm.stopPrank();
    }

    function test_deployer_ownership() public view {
        assertEq(
            multicall.isOwner(deployingUser),
            true,
            "Error setting deployer ownership"
        );
    }
}
