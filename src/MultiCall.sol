// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MultiCall {
    mapping(address => bool) private owners;
    address deployer;

    constructor() {
        deployer = msg.sender;
        owners[deployer] = true;
    }

    error NotAnOwner();
    error SubCallFailure(Call call, Result result);
    error NotDeployer();

    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);

    modifier onlyOwner(address caller) {
        bool isOwner = owners[caller];
        if (!isOwner) {
            revert NotAnOwner();
        }
        _;
    }

    modifier onlyDeployer(address caller) {
        if (caller != deployer) {
            revert NotDeployer();
        }
        _;
    }

    /**
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

    /**
     * @notice A single result from a call
     * @param isSuccess Whether the call was successful
     * @param returnData The return data from the call
     */
    struct Result {
        bool isSuccess;
        bytes returnData;
    }

    /**
     * @notice Aggregate multiple calls into a single call
     * @param calls The calls to aggregate
     * @return blockNumber The block number of the call and returnData The return data of the calls
     */
    function aggregate(
        Call[] calldata calls
    )
        external
        onlyOwner(msg.sender)
        returns (uint256 blockNumber, Result[] memory returnData)
    {
        blockNumber = block.number;
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call calldata call;
        for (uint256 i = 0; i < length; ) {
            call = calls[i];
            (returnData[i].isSuccess, returnData[i].returnData) = call
                .target
                .call(call.callData);
            if (!(returnData[i].isSuccess || call.allowFailure)) {
                revert SubCallFailure(call, returnData[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Add a new owner to the contract, only callable by the deployer
     * @param newOwner New owner to add
     */
    function addOwner(address newOwner) external onlyDeployer(msg.sender) {
        owners[newOwner] = true;
        emit OwnerAdded(newOwner);
    }

    /**
     * @notice Remove an existing owner from the contract, only callable by the deployer
     * @param existingOwner Owner to remove
     */
    function removeOwner(
        address existingOwner
    ) external onlyDeployer(msg.sender) {
        delete owners[existingOwner];
        emit OwnerRemoved(existingOwner);
    }
}
