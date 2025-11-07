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

abstract contract DataStorage{

    address public pledgee;
    uint256 public agreementId = 1;

    mapping(uint256 => Pledge) public pledges;
    mapping(address => uint256[]) public idByPledgor;

    mapping(address => mapping(uint256 => uint256)) public paymentsMade;

}