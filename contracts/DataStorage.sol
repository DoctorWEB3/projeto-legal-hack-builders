//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

struct Pledge {
    address pledgor;
    uint256 quantityInOunces;
    uint256 pledgeDate;
    uint256 redemptionDate;
    uint256 agreementId;
}

struct UserData{
    address user;
    uint256 principal;
}

contract DataStorage{

    address public pledgee;
    uint256 public agreementId = 1;

    mapping(uint256 => Pledge) public pledges;
    mapping(address => uint256) public idByPledgor;

    mapping(address => uint256) public reserve;
    mapping(address => UserData) public userBalances;

    address[] public investors;

    constructor(){
        pledgee = msg.sender;
    }

    function receiveData(Pledge memory pledgeAdded, uint256 pledgeId) external{
        pledges[pledgeId] = pledgeAdded;
    }

    function getPledgeById(uint256 pledgeId) external view returns (Pledge memory){
        return pledges[pledgeId];
    }

}