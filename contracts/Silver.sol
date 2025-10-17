// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./CriticalMoney.sol";

contract Silver is CriticalMoney {

    // troy ounce = 31,1034768 gramas 
    // ISO 4217 
    constructor() CriticalMoney("Critical Silver", "cAg", Unit.TroyOunce) {}

}