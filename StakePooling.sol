// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RewardToken.sol";
import "./ShineToken.sol";

contract StakePooling {
    // 质押奖励的发放速率
    uint256 public _rewardRate;

    // 每次有用户操作时，更新为当前时间
    uint256 public _lastUpdateTime;

    // 我们前面说到的每单位数量获得奖励的累加值，这里是乘上奖励发放速率后的值
    uint256 public _rewardPerToken;

    // 在单个用户维度上，为每个用户记录每次操作的累加值，同样也是乘上奖励发放速率后的值
    mapping(address => uint256) public _userRewardPerTokens;

    // 用户到当前时刻可领取的奖励数量
    mapping(address => uint256) public _userRewards;

    // 池子中质押总量
    uint256 private _totalSupply;

    // 用户的余额
    mapping(address => uint256) private _balances;

    RewardToken public _rewardToken;
    ShineToken public _stakeToken;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address rewardToken, address stakeToken) {
        _rewardToken  = RewardToken(rewardToken);
        _stakeToken = ShineToken(stakeToken);
        // 0.1 个代币每秒
        _rewardRate = 1e17;
    }

    // 计算当前时刻的累加值
    function rewardPerToken() public view returns (uint256) {
        // 如果池子里的数量为0，说明上一个区间内没有必要发放奖励，因此累加值不变
        if (_totalSupply == 0) {
            return _rewardPerToken;
        }

        // 计算累加值，上一个累加值加上最近一个区间的单位数量可获得的奖励数量
        return _rewardPerToken + (block.timestamp - _lastUpdateTime) * _rewardRate * 1e18 / _totalSupply;
    }

    // 计算用户可以领取的奖励数量
    // 质押数量 * （当前累加值 - 用户上次操作时的累加值）+ 上次更新的奖励数量
    function earned(address account) public view returns (uint256) {
        require (account != address(0), "earned: account is the zero address");
        return _balances[account] * (_rewardPerToken - _userRewardPerTokens[account]) / 1e18 + _userRewards[account];
    }

    modifier updateReward(address account) {
        // 更新累加值
        _rewardPerToken = rewardPerToken();
        // 更新最新有效时间戳
        _lastUpdateTime = block.timestamp;

        if (account != address(0)) {
            // 更新奖励数量
            _userRewards[account] = earned(account);
            // 更新用户的累加值
            _userRewardPerTokens[account] = _rewardPerToken;
        }
        _;
    }

    function stake(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply += amount;
        _balances[msg.sender] += amount;
        _stakeToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        _stakeToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function claim() public updateReward(msg.sender) {
        uint256 reward = _userRewards[msg.sender];
        if (reward > 0) {
            _userRewards[msg.sender] = 0;
            _rewardToken.mint(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() public {
        withdraw(_balances[msg.sender]);
        claim();
    }

}