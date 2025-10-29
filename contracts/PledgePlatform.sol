// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Silver.sol';
import './DataStorage.sol';


interface IXAGPrice{
    function getXAGPriceUpdated() external view returns (uint256);
}

interface ILendingPool{
    function borrow(address pledgor, uint256 amount, uint256 spread) external;
    function updateReserve(uint256 payment) external returns (uint256);
}

interface ISilver {
    function mint(address to, uint256 amount) external;
    function changeWhitelist(address account, bool status) external;
}

contract PledgePlatform is Silver, DataStorage{

    ISilver public silver;
    IXAGPrice public xagPrice;
    ILendingPool public lendingPool;
    IERC20 private immutable usdcAddress;

    address usdcToken = 0x9Dfc8C3143E01cA01A90c3E313bA31bFfD9C1BA9;

    constructor(address _silver, address _xagPrice, address _lendingPool){
        pledgee = msg.sender;
        silver = ISilver(_silver);
        xagPrice = IXAGPrice(_xagPrice);
        lendingPool = ILendingPool(_lendingPool);
        usdcAddress = IERC20(usdcToken);
    }

    modifier onlyPledgee {
        require(msg.sender == pledgee, "You're not the pledgee");
        _;
    }

    function pledgeRegistry(address _pledgor, uint256 amount, uint256 spread) external onlyPledgee{
        require(amount > 0, "This quantity is invalid");

        silver.changeWhitelist(_pledgor, true);

        uint256 priceRaw = xagPrice.getXAGPriceUpdated();

            pledges[agreementId] = Pledge({
                pledgor: _pledgor,
                quantityInOunces: amount,
                pledgeDate: block.timestamp,
                redemptionDate: block.timestamp + 365 days,
                agreementId: agreementId,
                redemptionApproved: false,
                ouncePrice: priceRaw
            });

            idByPledgor[_pledgor].push(agreementId);
            agreementId++;
        
        silver.mint(_pledgor, amount);

        uint256 usdcAmount = (amount * priceRaw) / 1e14;

        lendingPool.borrow(_pledgor, usdcAmount, spread);
    }

    function getPledgeById(uint256 pledgeId) external view returns (Pledge memory){
        return pledges[pledgeId];
    }

    function getPledgorById(address pledgor) external view returns (uint256[] memory) {
        return idByPledgor[pledgor];
    }

    function amortizePledge(uint256 amount, uint256 pledgeId) external virtual returns (uint256) {
    require(msg.sender == pledges[pledgeId].pledgor, "Address without registry");

    uint256 totalDebtUSDC = (pledges[pledgeId].quantityInOunces * pledges[pledgeId].ouncePrice) / 1e14;
    uint256 paidSoFar = paymentsMade[msg.sender][pledgeId];
    uint256 paymentsLeft = totalDebtUSDC - paidSoFar;

    require(amount <= paymentsLeft, "Amount overflow");

    usdcAddress.transferFrom(msg.sender, address(this), amount);
    usdcAddress.approve(address(this), amount);
    usdcAddress.transferFrom(address(this), address(lendingPool), amount);

    lendingPool.updateReserve(amount);

    paymentsMade[msg.sender][pledgeId] += amount;

    if (paymentsMade[msg.sender][pledgeId] >= totalDebtUSDC) {
        pledges[pledgeId].redemptionApproved = true;
    } else {
        pledges[pledgeId].redemptionApproved = false;
    }

    return paymentsMade[msg.sender][pledgeId];
}




}