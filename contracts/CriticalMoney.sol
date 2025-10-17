// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./uRWA20.sol";

abstract contract CriticalMoney is uRWA20 {

    enum Unit {
        TroyOunce,
        Gram
    }
    
    Unit public unit;

    constructor(string memory _name, string memory _symbol, Unit _unit) uRWA20(_name, _symbol, msg.sender) {
        unit = _unit;
    }

}