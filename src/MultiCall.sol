// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MultiCall {
    struct Call {
        address target;
        bytes callData;
        bool allowFailure;
    }

    struct Result {
        bool isSuccess;
        bytes returnData;
    }

    function aggregate(
        Call[] calldata calls
    ) external returns (uint256 blockNumber, Result[] memory returnData) {
        blockNumber = block.number;
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call calldata call;
        for (uint256 i = 0; i < length; ) {
            call = calls[i];
            (returnData[i].isSuccess, returnData[i].returnData) = call
                .target
                .call(call.callData);
            require(
                (returnData[i].isSuccess || call.allowFailure),
                "Multicall: sub-call failed"
            );
            unchecked {
                ++i;
            }
        }
    }
}
