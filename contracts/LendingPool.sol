//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import './IERC20.sol';
import './DataStorage.sol';

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IDataStorage{
    function getPledgeById(uint256 pledgeId) external view returns (Pledge memory);
}

contract LendingPool is DataStorage, ReentrancyGuard{

    event PaymentReceived(address indexed payer, uint256 amount);

    IDataStorage public dataStorage;
    IERC20 private immutable usdcAddress;

    // ATTORNEYCOIN
    address usdcToken; // = 0xABS123;

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
        usdcAddress.approve(address(this), amount);
        
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

    function borrow(uint256 amount, uint256 spread, uint256 currentId) external {
        require(amount <= reserve[address(this)], "It doesn't have sufficient funds in reserve");

        uint256 totalReserve = reserve[address(this)];
        uint256 reward;

        if (totalReserve >= 20000 * 1e6 && totalReserve < 40000 * 1e6){
            reward =  (spread * 10) / 100;
        } else if (totalReserve >= 40000 * 1e6 && totalReserve < 60000 * 1e6){
             reward = (spread * 20)  / 100;
        } else if (totalReserve >= 60000 * 1e6 && totalReserve < 80000 * 1e6){
            reward = (spread * 30)  / 100;
        } else if (totalReserve >= 80000 * 1e6 && totalReserve < 100000 * 1e6){
            reward = (spread * 40)  / 100;
        } else {
            reward = (spread * 50)  / 100;
        }

        address currentPledgor = dataStorage.getPledgeById(currentId).pledgor;
        usdcAddress.transfer(currentPledgor, amount);
        uint256 pledgeeFee = spread - reward;

        distributeRewards(reward);

        usdcAddress.transfer(pledgee, pledgeeFee);

        totalReserve -= (amount + reward + pledgeeFee);
    }

    function distributeRewards(uint256 totalReward) internal nonReentrant {
        require(totalReward > 0, "No reward to distribute");
        require(reserve[address(this)] > 0, "Empty reserve");

        uint256 totalReserve = reserve[address(this)];

        uint256 totalDistributed;

        for (uint256 i = 0; i < investors.length; i++) {
            address investor = investors[i];
            uint256 share = (userBalances[investor].principal /*   * 1e18   */) / totalReserve; // percentual (escala 18)
            uint256 reward = (totalReward * share) / 1e18; // recompensa proporcional
            usdcAddress.transfer(userBalances[investor].user, reward);
            totalDistributed += reward;
        }

        require(totalDistributed <= totalReward, "Distribution overflow");
    }
}