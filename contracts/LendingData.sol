//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

struct UserData{
    address user;
    uint256 principal;
}

abstract contract LendingData{
    uint256 public pendingRewards;

    mapping(address => uint256[]) public idByPledgor;

    mapping(address => uint256) public reserve;
    mapping(address => UserData) public userBalances;
    mapping (address => bool) public isInvestor;
    mapping(address => uint256) public rewards;

    mapping(address => uint256) public redemptions;

    address[] public investors;
}