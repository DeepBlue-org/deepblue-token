// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title DeepBlue Farm — Synthetix-style staking rewards
/// @notice Users stake Uniswap LP tokens, earn $DBB rewards over time
/// @dev Based on Synthetix StakingRewards pattern (battle-tested, gas-efficient)
contract DeepBlueFarm {
    // ── State ──
    address public owner;
    address public rewardToken;   // $DBB token
    address public stakingToken;  // Uniswap LP token

    uint256 public rewardRate;        // rewards per second
    uint256 public periodFinish;      // when current reward period ends
    uint256 public rewardsDuration;   // length of reward period in seconds
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint256 public totalStaked;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    bool public paused;

    // ── Events ──
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardPeriodStarted(uint256 reward, uint256 duration);
    event Paused(bool isPaused);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    // ── Modifiers ──
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notPaused() {
        require(!paused, "Farm is paused");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /// @param _rewardToken $DBB token address
    /// @param _stakingToken Uniswap LP token address
    constructor(address _rewardToken, address _stakingToken) {
        require(_rewardToken != address(0) && _stakingToken != address(0), "Zero address");
        owner = msg.sender;
        rewardToken = _rewardToken;
        stakingToken = _stakingToken;
    }

    // ── Views ──

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (
            (lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18 / totalStaked
        );
    }

    function earned(address account) public view returns (uint256) {
        return (
            stakedBalance[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18
        ) + rewards[account];
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    // ── User functions ──

    function stake(uint256 amount) external notPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        totalStaked += amount;
        stakedBalance[msg.sender] += amount;
        _safeTransferFrom(stakingToken, msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(stakedBalance[msg.sender] >= amount, "Insufficient staked balance");
        totalStaked -= amount;
        stakedBalance[msg.sender] -= amount;
        _safeTransfer(stakingToken, msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function claimReward() public updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            _safeTransfer(rewardToken, msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /// @notice Withdraw all staked tokens and claim rewards
    function exit() external updateReward(msg.sender) {
        uint256 staked = stakedBalance[msg.sender];
        if (staked > 0) {
            totalStaked -= staked;
            stakedBalance[msg.sender] = 0;
            _safeTransfer(stakingToken, msg.sender, staked);
            emit Withdrawn(msg.sender, staked);
        }
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            _safeTransfer(rewardToken, msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // ── Owner functions ──

    /// @notice Fund a new reward period. Transfers `reward` DBB from owner to this contract.
    /// @param reward Total DBB to distribute over `duration` seconds
    /// @param duration Period length in seconds (e.g. 7776000 = 90 days)
    function notifyRewardAmount(uint256 reward, uint256 duration) external onlyOwner updateReward(address(0)) {
        require(duration > 0, "Duration must be > 0");
        require(reward > 0, "Reward must be > 0");

        // Pull reward tokens from owner
        _safeTransferFrom(rewardToken, msg.sender, address(this), reward);

        rewardsDuration = duration;

        if (block.timestamp >= periodFinish) {
            // New period
            rewardRate = reward / duration;
        } else {
            // Extend existing period — add leftover + new
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (leftover + reward) / duration;
        }

        require(rewardRate > 0, "Reward rate = 0");
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + duration;

        emit RewardPeriodStarted(reward, duration);
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero owner");
        address old = owner;
        owner = newOwner;
        emit OwnershipTransferred(old, newOwner);
    }

    /// @notice Emergency: recover tokens accidentally sent to this contract
    /// @dev Cannot recover staking token while stakers exist
    function recoverERC20(address token, uint256 amount) external onlyOwner {
        require(token != stakingToken || totalStaked == 0, "Cannot recover staked tokens");
        _safeTransfer(token, owner, amount);
    }

    // ── Internal safe ERC20 calls ──

    function _safeTransfer(address token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, amount) // transfer(address,uint256)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer failed");
    }

    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, amount) // transferFrom(address,address,uint256)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferFrom failed");
    }
}
