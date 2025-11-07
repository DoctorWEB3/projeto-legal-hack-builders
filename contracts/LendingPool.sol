//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import './IERC20.sol';
import './LendingData.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract LendingPool is LendingData, ReentrancyGuard {

    event PaymentReceived(address indexed payer, uint256 indexed amount);
    event RewardClaimed(address indexed investor, uint256 indexed reward);
   
    IERC20 private immutable usdcAddress;
    address usdcToken = 0x9Dfc8C3143E01cA01A90c3E313bA31bFfD9C1BA9;

    constructor() {
        pledgee = msg.sender;
        usdcAddress = IERC20(usdcToken);
    }

    function allowanceUsdc() public view returns (uint256 usdcAmount) {
        usdcAmount = usdcAddress.allowance(msg.sender, address(this));
    }

    function balancesOf(address account) public view returns (uint256) {
        return usdcAddress.balanceOf(account);
    }

    function lendUSDC(uint256 amount) external nonReentrant {
        require(usdcAddress.balanceOf(msg.sender) >= amount, "Amount must be greater than zero");
        require(usdcAddress.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");

        usdcAddress.transferFrom(msg.sender, address(this), amount);
        reserve[address(this)] += amount;

        uint256 amountDeposited = userBalances[msg.sender].principal += amount;
        userBalances[msg.sender] = UserData({ user: msg.sender, principal: amountDeposited });

        if (!isInvestor[msg.sender]) {
            investors.push(msg.sender);
            isInvestor[msg.sender] = true;
        }

        emit PaymentReceived(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(userBalances[msg.sender].principal >= amount, "Amount must be greater than zero");
        require(reserve[address(this)] >= amount, "Insufficient contract reserve");

        usdcAddress.transfer(msg.sender, amount);

        reserve[address(this)] -= amount;
        uint256 remainingAmount = userBalances[msg.sender].principal -= amount;
        userBalances[msg.sender] = UserData({ user: msg.sender, principal: remainingAmount });
    }

    function borrow(address pledgor, uint256 usdcAmount, uint256 spread) external virtual returns (bool) {
        uint256 totalReserve = reserve[address(this)];

        require(usdcAmount <= totalReserve, "Insufficient free reserve (rewards locked)");

        uint256 liquidValue = calculateCreditWithSpread(usdcAmount, spread);
        uint256 spreadAmount = usdcAmount - liquidValue;

        uint256 rewardPercent;
        if (spreadAmount < 20000 * 1e6){
            rewardPercent = 5;
        } else if (spreadAmount >= 20000 * 1e6 && spreadAmount < 40000 * 1e6){
            rewardPercent = 10;
        } else if (spreadAmount >= 40000 * 1e6 && spreadAmount < 60000 * 1e6){
            rewardPercent = 20;
        } else if (spreadAmount >= 60000 * 1e6 && spreadAmount < 80000 * 1e6){
            rewardPercent = 30;
        } else if (spreadAmount >= 80000 * 1e6 && spreadAmount < 100000 * 1e6){
            rewardPercent = 40;
        } else {
            rewardPercent = 50;
        }

        uint256 pledgeeFee = (spreadAmount * (100 - rewardPercent)) / 100;
        uint256 rewardAmount = spreadAmount - pledgeeFee;

        usdcAddress.transfer(pledgor, liquidValue);
        distributeRewards(rewardAmount);
        usdcAddress.transfer(pledgee, pledgeeFee);

        reserve[address(this)] -= (liquidValue + pledgeeFee);

        return true;
    }


    function calculateCreditWithSpread(uint256 amount, uint256 spreadPercent) internal pure returns (uint256 liquidValue) {
        require(spreadPercent <= 12, "Invalid spread");
        liquidValue = (amount * (100 - spreadPercent)) / 100;
    }

    function distributeRewards(uint256 totalReward) internal nonReentrant {
        require(totalReward > 0, "No reward to distribute");
        uint256 totalReserve = reserve[address(this)];
        require(totalReserve >= totalReward, "Insufficient reserve for rewards");

        uint256 totalDistributed;

        for (uint256 i = 0; i < investors.length; i++) {
            address investor = userBalances[investors[i]].user;
            uint256 principal = userBalances[investor].principal;
            uint256 share = (principal * 1e6) / totalReserve;
            uint256 reward = (totalReward * share) / 1e6;

            rewards[investor] += reward;
            totalDistributed += reward;
        }

        reserve[address(this)] -= totalDistributed;
        pendingRewards += totalDistributed;

    }

    function updateReserve(uint256 payment) external virtual returns (uint256) {
        return reserve[address(this)] += payment;
    }

    function claimRewards() external nonReentrant {
        require(msg.sender == userBalances[msg.sender].user, "You don't have rewards to claim");
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        require(usdcAddress.balanceOf(address(this)) >= reward, "Insufficient balance in the contract");

        pendingRewards -= reward;
        rewards[msg.sender] = 0;
        usdcAddress.transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }
}
