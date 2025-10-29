//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

struct Pledge {
    address pledgor;
    uint256 quantityInOunces;
    uint256 pledgeDate;
    uint256 redemptionDate;
    uint256 agreementId;
    bool redemptionApproved;
    uint256 ouncePrice;
}

struct UserData{
    address user;
    uint256 principal;
}

contract DataStorage{

    address public pledgee;
    uint256 public agreementId = 1;

    uint256 public pendingRewards;

    mapping(uint256 => Pledge) public pledges;
    mapping(address => uint256[]) public idByPledgor;

    mapping(address => uint256) public reserve;
    mapping(address => UserData) public userBalances;
    mapping (address => bool) public isInvestor;
    mapping(address => uint256) public rewards;

    mapping(address => uint256) public redemptions;
    mapping(address => mapping(uint256 => uint256)) public paymentsMade;

    address[] public investors;

    constructor(){
        pledgee = msg.sender;
    }

}