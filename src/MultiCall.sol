// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiCall is ReentrancyGuard {
    mapping(address => bool) private owners;
    address public deployer;
    uint256 public maxCalls;

    constructor(uint256 _maxCalls) {
        deployer = msg.sender;
        owners[deployer] = true;
        maxCalls = _maxCalls;
        emit DeployerSet(deployer);
        emit OwnerAdded(deployer);
    }

    error NotAnOwner();
    error SubCallFailure(Call call, Result result);
    error NotDeployer();
    error ZeroAddress();
    error TooManyCalls();

    event DeployerSet(address indexed newDeployer);
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event AggregateExecuted(
        address indexed caller,
        uint256 callCount,
        uint256 blockNumber
    );
    event DrainSuccess(
        address indexed recipient,
        uint256 amount,
        address indexed token
    );
    event DrainFailure(
        address indexed recipient,
        uint256 amount,
        address indexed token
    );
    event MaxCallsUpdated(uint256 newMaxCalls);

    modifier onlyOwner() {
        if (!owners[msg.sender]) {
            revert NotAnOwner();
        }
        _;
    }

    modifier onlyDeployer() {
        if (msg.sender != deployer) {
            revert NotDeployer();
        }
        _;
    }

    modifier noZeroAddress(address user) {
        if (user == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    modifier maxCallsCheck(uint256 callCount) {
        if (callCount > maxCalls) {
            revert TooManyCalls();
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
        uint256 value;
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
        onlyOwner
        nonReentrant
        maxCallsCheck(calls.length)
        returns (uint256 blockNumber, Result[] memory returnData)
    {
        blockNumber = block.number;
        uint256 length = calls.length;
        returnData = new Result[](length);
        for (uint256 i = 0; i < length; ) {
            Call calldata call = calls[i];
            (returnData[i].isSuccess, returnData[i].returnData) = call
                .target
                .call{value: call.value}(call.callData);
            if (!(returnData[i].isSuccess || call.allowFailure)) {
                revert SubCallFailure(call, returnData[i]);
            }
            unchecked {
                ++i;
            }
        }
        emit AggregateExecuted(msg.sender, length, blockNumber);
        return (blockNumber, returnData);
    }

    /**
     * @notice Add a new owner to the contract, only callable by the deployer
     * @param newOwner New owner to add
     */
    function addOwner(
        address newOwner
    ) external onlyDeployer noZeroAddress(newOwner) {
        owners[newOwner] = true;
        emit OwnerAdded(newOwner);
    }

    /**
     * @notice Remove an existing owner from the contract, only callable by the deployer
     * @param existingOwner Owner to remove
     */
    function removeOwner(
        address existingOwner
    ) external onlyDeployer noZeroAddress(existingOwner) {
        delete owners[existingOwner];
        emit OwnerRemoved(existingOwner);
    }

    /**
     * @notice View function to check if an address is an owner
     * @param user Address to check owner status
     */
    function isOwner(address user) external view returns (bool) {
        return owners[user];
    }

    /**
     * @notice Drain funds from the contract (while destroying contract)
     * @param recipient Address to send funds to
     * @param token_address Address of token to drain, if zero address, Native token holding is drained
     */
    function drainFunds(
        address recipient,
        address token_address
    ) external onlyDeployer nonReentrant noZeroAddress(recipient) {
        Result memory result;
        uint256 drainAmount;
        if (token_address == address(0)) {
            drainAmount = address(this).balance;
            (result.isSuccess, result.returnData) = recipient.call{
                value: drainAmount
            }("");
        } else {
            IERC20 token = IERC20(token_address);
            drainAmount = token.balanceOf(address(this));
            result.isSuccess = token.transfer(recipient, drainAmount);
        }
        if (result.isSuccess) {
            emit DrainSuccess(recipient, drainAmount, token_address);
        } else {
            emit DrainFailure(recipient, drainAmount, token_address);
        }
    }

    /**
     * @notice Change the deployer of the contract
     * @param newDeployer New deployer to set
     */
    function changeDeployer(
        address newDeployer
    ) external onlyDeployer noZeroAddress(newDeployer) {
        deployer = newDeployer;
        if (!owners[newDeployer]) {
            owners[newDeployer] = true;
            emit OwnerAdded(newDeployer);
        }
        emit DeployerSet(newDeployer);
    }

    /**
     * @notice Change the max number of calls that can be made in a single aggregate call
     * @param newMaxCalls New max calls to set
     */
    function changeMaxCalls(uint256 newMaxCalls) external onlyOwner {
        maxCalls = newMaxCalls;
        emit MaxCallsUpdated(newMaxCalls);
    }

    receive() external payable {}
}
