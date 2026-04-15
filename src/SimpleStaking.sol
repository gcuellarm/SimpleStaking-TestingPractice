// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleStaking {
    error ZeroAmount();
    error InsufficientBalance();

    uint256 public totalStaked;
    uint256 public rewardRate = 1e16; // rewards per second (0.01 ETH/sec)
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    constructor() {
        lastUpdateTime = block.timestamp;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + ((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / totalStaked;
    }

    function earned(address account) public view returns (uint256) {
        return (balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18 + rewards[account];
    }

    function updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    function stake() external payable {
        if (msg.value == 0) revert ZeroAmount();

        updateReward(msg.sender);

        balances[msg.sender] += msg.value;
        totalStaked += msg.value;
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        if (balances[msg.sender] < amount) revert InsufficientBalance();

        updateReward(msg.sender);

        balances[msg.sender] -= amount;
        totalStaked -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success);
    }

    function claimReward() external {
        updateReward(msg.sender);

        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: reward}("");
        require(success);
    }

    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
