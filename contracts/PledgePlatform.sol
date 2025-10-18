// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Silver.sol';
import './DataStorage.sol';

interface IXAGPrice{
    function getXAGPriceUpdated() external view returns (uint256);
}

interface ILendingPool{
    function borrow(address pledgor, uint256 amount, uint256 spread, uint256 currentId) external;
}

interface ISilver {
    function mint(address to, uint256 amount) external;
    function changeWhitelist(address account, bool status) external;
}

interface IDataStorage{
    function receiveData(Pledge memory pledgeAdded, uint256 pledgeId) external;
}

contract PledgePlatform is Silver, DataStorage{

    ISilver public silver;
    IXAGPrice public xagPrice;
    ILendingPool public lendingPool;
    IDataStorage public dataStorage;

    constructor(address _silver, address _xagPrice, address _lendingPool, address _dataStorage){
        pledgee = msg.sender;
        silver = ISilver(_silver);
        xagPrice = IXAGPrice(_xagPrice);
        lendingPool = ILendingPool(_lendingPool);
        dataStorage = IDataStorage(_dataStorage);
    }

    modifier onlyPledgee {
        require(msg.sender == pledgee, "You're not the pledgee");
        _;
    }

    function pledgeRegistry(address _pledgor, uint256 amount, uint256 spread) external onlyPledgee{
        require(amount > 0, "This quantity is invalid");

        silver.changeWhitelist(_pledgor, true);

        uint256 currentId = idByPledgor[_pledgor];

        if (currentId == 0) {
            pledges[agreementId] = Pledge({
                pledgor: _pledgor,
                quantityInOunces: amount,
                pledgeDate: block.timestamp,
                redemptionDate: block.timestamp + 365 days,
                agreementId: agreementId
            });

            idByPledgor[_pledgor] = agreementId;
            agreementId++;
        } else {
            pledges[currentId].quantityInOunces = amount;
            pledges[currentId].redemptionDate = block.timestamp + 365 days;
            pledges[currentId].pledgeDate = block.timestamp;
        }

        silver.mint(_pledgor, amount);

        uint256 priceRaw = xagPrice.getXAGPriceUpdated();
        uint256 borrowedAmount = (amount * priceRaw) / 1e14;
        uint256 liquidValue = calculateCreditWithSpread(borrowedAmount, spread);

        lendingPool.borrow(_pledgor, liquidValue, spread, currentId);
    }

    function calculateCreditWithSpread(uint256 amount, uint256 spreadPercent) internal pure returns (uint256 liquidValue) {
        require(spreadPercent <= 12, "invalid spread");
        liquidValue = (amount * (100 - spreadPercent)) / 100;
    }
}
