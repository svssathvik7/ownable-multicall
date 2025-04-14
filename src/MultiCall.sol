// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MultiCall {
    /*
     * @notice A single call to target a contract with a given callData
     * @param target The contract to call
     * @param callData The data to pass to the contract
     * @param allowFailure Whether to allow the sub-call to fail
     */
    struct Call {
        address target;
        bytes callData;
        bool allowFailure;
    }

    /*
     * @notice A single result from a call
     * @param isSuccess Whether the call was successful
     * @param returnData The return data from the call
     */
    struct Result {
        bool isSuccess;
        bytes returnData;
    }

    /*
     * @notice Aggregate multiple calls into a single call
     * @param calls The calls to aggregate
     * @return blockNumber The block number of the call and returnData The return data of the calls
     */
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
