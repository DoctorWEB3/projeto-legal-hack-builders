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
    //IDataStorage public dataStorage;
    IERC20 private immutable usdcAddress;

    address usdcToken = 0x9Dfc8C3143E01cA01A90c3E313bA31bFfD9C1BA9;

    constructor(address _silver, address _xagPrice, address _lendingPool){
        pledgee = msg.sender;
        silver = ISilver(_silver);
        xagPrice = IXAGPrice(_xagPrice);
        lendingPool = ILendingPool(_lendingPool);
        //dataStorage = IDataStorage(_dataStorage);
        usdcAddress = IERC20(usdcToken);
    }

    modifier onlyPledgee {
        require(msg.sender == pledgee, "You're not the pledgee");
        _;
    }

    function pledgeRegistry(address _pledgor, uint256 amount, uint256 spread) external onlyPledgee{
        require(amount > 0, "This quantity is invalid");

        silver.changeWhitelist(_pledgor, true);

        //uint256 currentId = idByPledgor[_pledgor];

            pledges[agreementId] = Pledge({
                pledgor: _pledgor,
                quantityInOunces: amount,
                pledgeDate: block.timestamp,
                redemptionDate: block.timestamp + 365 days,
                agreementId: agreementId,
                redemptionApproved: false
            });

            idByPledgor[_pledgor] = agreementId;
            agreementId++;
        
        silver.mint(_pledgor, amount);

        uint256 priceRaw = xagPrice.getXAGPriceUpdated();
        uint256 borrowedAmount = (amount * priceRaw) / 1e14;
        uint256 liquidValue = calculateCreditWithSpread(borrowedAmount, spread);

        lendingPool.borrow(_pledgor, liquidValue, spread);
    }

    function calculateCreditWithSpread(uint256 amount, uint256 spreadPercent) internal pure returns (uint256 liquidValue) {
        require(spreadPercent <= 12, "invalid spread");
        liquidValue = (amount * (100 - spreadPercent)) / 100;
    }

    function getPledgeById(uint256 pledgeId) external view returns (Pledge memory){
        return pledges[pledgeId];
    }

    function getPledgorById(address pledgor) external view returns (uint256) {
        return idByPledgor[pledgor];
    }

    function amortizePledge(uint256 amount, uint256 pledgeId) external virtual {
        require(msg.sender == pledges[pledgeId].pledgor, "Address without registry");

        uint256 priceRaw = xagPrice.getXAGPriceUpdated();

        uint256 amortizationAmount = pledges[pledgeId].quantityInOunces * priceRaw;
        require(amount <= amortizationAmount, "Amount overflow");

        usdcAddress.transferFrom(msg.sender, address(this), amount);

        usdcAddress.approve(address(this), amount);
        usdcAddress.transferFrom(address(this), address(lendingPool), amount);

        lendingPool.updateReserve(amount);

        uint256 discount = (amount * 1e14) / priceRaw;
        pledges[pledgeId].quantityInOunces -= discount;

        if (amount == amortizationAmount){
            pledges[pledgeId].redemptionApproved = true;
        } else {
            pledges[pledgeId].redemptionApproved = false;
        }
    }


}