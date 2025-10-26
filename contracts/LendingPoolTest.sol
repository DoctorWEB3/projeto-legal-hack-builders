//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import './IERC20.sol';
import './DataStorage.sol';

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IDataStorage{
    function receiveData(Pledge memory pledgeAdded, uint256 pledgeId) external;
}

contract LendingPool is DataStorage, ReentrancyGuard{

    event PaymentReceived(address indexed payer, uint256 indexed amount);
    event RewardClaimed(address indexed investor, uint256 indexed reward);
   
    IERC20 private immutable usdcAddress;

    address usdcToken = 0x9Dfc8C3143E01cA01A90c3E313bA31bFfD9C1BA9;

    constructor(){
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
        
        usdcAddress.allowance(msg.sender, address(this));
        require(usdcAddress.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
        
        usdcAddress.transferFrom(msg.sender, address(this), amount);

        reserve[address(this)] += amount;

        uint256 amountDeposited = userBalances[msg.sender].principal += amount;

        userBalances[msg.sender] = UserData({
            user: msg.sender,
            principal: amountDeposited
            //investorId: investorId
        });

        investors.push(msg.sender);

        //investorId++;

        emit PaymentReceived(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(userBalances[msg.sender].principal >= amount, "Amount must be greater than zero");
        usdcAddress.approve(msg.sender, amount);

        usdcAddress.allowance(address(this), msg.sender);
        require(usdcAddress.allowance(address(this), msg.sender) >= amount, "Insufficient allowance");

        usdcAddress.transferFrom(address(this), msg.sender, amount);

        reserve[address(this)] -= amount;

        uint256 remainingAmount = userBalances[msg.sender].principal -= amount;

        userBalances[msg.sender] = UserData({
            user: msg.sender,
            principal: remainingAmount
        });
    }

    function borrow(address pledgor, uint256 amount, uint256 spread) external virtual returns (bool){
        require(amount <= reserve[address(this)], "It doesn't have sufficient funds in reserve");

        uint256 totalReserve = reserve[address(this)];
        totalReserve -= pendingRewards;

        uint256 rewardPercent;

        if (spread < 20000 * 1e6){
            rewardPercent = 5;
        } else if (spread >= 20000 * 1e6 && spread < 40000 * 1e6){
            rewardPercent = 10;
        } else if (spread >= 40000 * 1e6 && spread < 60000 * 1e6){
            rewardPercent = 20;
        } else if (spread >= 60000 * 1e6 && spread < 80000 * 1e6){
            rewardPercent = 30;
        } else if (spread >= 80000 * 1e6 && spread < 100000 * 1e6){
            rewardPercent = 40;
        } else {
            rewardPercent = 50;
        }

        uint256 feeAmount = (amount * spread) / 100;
        uint256 rewardAmount = (feeAmount * rewardPercent) / 100;

        uint256 pledgeeFee = feeAmount - rewardAmount;

        usdcAddress.transfer(pledgor, amount);

        distributeRewards(rewardAmount);

        usdcAddress.transfer(pledgee, pledgeeFee);

        totalReserve -= (amount + feeAmount);
        return true;
    }

    function distributeRewards(uint256 totalReward) internal nonReentrant returns (uint256){

        require(totalReward > 0, "No reward to distribute");
        require(reserve[address(this)] > 0, "Empty reserve");

        uint256 totalReserve = reserve[address(this)];

        uint256 totalDistributed;

        for (uint256 i = 0; i < investors.length; i++) {
            address investor = userBalances[investors[i]].user;
            uint256 principal = userBalances[investor].principal;
            uint256 share = (principal * 1e6) / totalReserve;
            uint256 reward = (totalReward * share) / 1e6;

            totalDistributed += reward;
            rewards[investor] += reward;
        }

        pendingRewards += totalDistributed;

        require(totalDistributed <= totalReward, "Distribution overflow");
        require(totalDistributed <= pendingRewards, "Distribution of reward funds failed");
        return totalDistributed;
    }

    function updateReserve(uint256 payment) external virtual returns (uint256){
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
