// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './IERC20.sol';

contract Attorneycoin {
    string public name = "Attorneycoin";
    string public symbol = "ATC";
    uint8 public decimals = 6;
    uint256 public totalSupply;

    address public admin;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Optional: Track how many times a user minted (could also track time-based)
    mapping(address => uint256) public userMintedAmount;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Mint(address indexed _to, uint256 _value);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    constructor() {
        admin = msg.sender;
        totalSupply = 1000000 * 10 ** decimals;
        _balances[admin] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(_balances[msg.sender] >= _value, "Insufficient balance");

        _balances[msg.sender] -= _value;
        _balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return _allowances[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_balances[_from] >= _value, "Insufficient funds");
        require(_allowances[_from][msg.sender] >= _value, "Insufficient authorization");

        _balances[_from] -= _value;
        _allowances[_from][msg.sender] -= _value;
        _balances[_to] += _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @notice Usuários mintam até 'userMintLimit' ATC
    function mintToUser() external {
        uint256 userMintLimit = 10 * 10 ** 6;

        if ((block.timestamp - userMintedAmount[msg.sender]) > 1 days){
            userMintLimit = 10 * 10 ** 6;
            userMintedAmount[msg.sender] = 0;
            }
        
        require(userMintedAmount[msg.sender] < 1 days, "User mint deadline reached");

        uint256 minted = userMintLimit - _balances[msg.sender];
        require(userMintLimit > _balances[msg.sender], "Your balance can't be more than the mint limit");

        _balances[msg.sender] += minted;
        totalSupply += minted;
        userMintedAmount[msg.sender]= block.timestamp;

        emit Mint(msg.sender, minted);
        emit Transfer(address(0), msg.sender, minted);
        
    }

    /// @notice Admin minta quantos quiser para si mesmo
    function adminMint(uint256 minted) external onlyAdmin {
        _balances[admin] += minted;
        totalSupply += minted;

        emit Mint(admin, minted);
        emit Transfer(address(0), admin, minted);
    }
}
