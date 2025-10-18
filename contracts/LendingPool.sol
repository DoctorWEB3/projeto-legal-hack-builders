//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import './IERC20.sol';
import './DataStorage.sol';

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IDataStorage{
    function receiveData(Pledge memory pledgeAdded, uint256 pledgeId) external;
}

contract LendingPool is DataStorage, ReentrancyGuard{

    event PaymentReceived(address indexed payer, uint256 amount);

    IDataStorage public dataStorage;
    IERC20 private immutable usdcAddress;

    mapping(address => uint256) public reserve;
    mapping(address => UserData) public userBalances;

    address usdcToken = 0x9Dfc8C3143E01cA01A90c3E313bA31bFfD9C1BA9;

    constructor(address _dataStorage){
        pledgee = msg.sender;
        dataStorage = IDataStorage(_dataStorage);
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
        //usdcAddress.approve(address(this), amount);
        
        usdcAddress.allowance(msg.sender, address(this));
        require(usdcAddress.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
        
        usdcAddress.transferFrom(msg.sender, address(this), amount);

        reserve[address(this)] += amount;

        uint256 amountDeposited = userBalances[msg.sender].principal += amount;

        userBalances[msg.sender] = UserData({
            user: msg.sender,
            principal: amountDeposited
        });

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

    function borrow(address pledgor, uint256 amount, uint256 spread, uint256 currentId) external {
        require(amount <= reserve[address(this)], "It doesn't have sufficient funds in reserve");

        uint256 totalReserve = reserve[address(this)];
        uint256 rewardPercent;

        if (totalReserve >= 20000 * 1e6 && totalReserve < 40000 * 1e6){
            rewardPercent = 10;
        } else if (totalReserve >= 40000 * 1e6 && totalReserve < 60000 * 1e6){
            rewardPercent = 20;
        } else if (totalReserve >= 60000 * 1e6 && totalReserve < 80000 * 1e6){
            rewardPercent = 30;
        } else if (totalReserve >= 80000 * 1e6 && totalReserve < 100000 * 1e6){
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

        dataStorage.receiveData(pledges[currentId], currentId);

        totalReserve -= (amount + feeAmount);
    }

    function distributeRewards(uint256 totalReward) internal nonReentrant {
        require(totalReward > 0, "No reward to distribute");
        require(reserve[address(this)] > 0, "Empty reserve");

        uint256 totalReserve = reserve[address(this)];

        uint256 totalDistributed;

        for (uint256 i = 0; i < investors.length; i++) {
            address investor = investors[i];
            uint256 principal = userBalances[investor].principal;
            uint256 share = (principal * 1e6) / totalReserve;
            uint256 reward = (totalReward * share) / 1e6;
            usdcAddress.transfer(userBalances[investor].user, reward);
            totalDistributed += reward;
        }

        require(totalDistributed <= totalReward, "Distribution overflow");
    }
}
