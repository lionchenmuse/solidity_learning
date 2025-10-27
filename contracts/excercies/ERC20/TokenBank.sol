// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseERC20.sol";


contract TokenBank {
    BaseERC20 private token;

    mapping (address => uint256) private _deposits; // Mapping to store user deposits
    uint256 private _totalDeposits;
    address private _admin;

    event SetAdmin(address indexed oldAdmin, address indexed newAdmin);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    error NotAdmin(address user);
    error InsufficientBalance(address user, uint256 balance, uint256 needed);
    error TransferFailed(address user);

    modifier onlyAdmin() {
        require(msg.sender == _admin, NotAdmin(msg.sender));
        _;
    }

    constructor(address tokenAddress) {
        token = BaseERC20(tokenAddress);
        _admin = msg.sender;
    }

    function checkDeposit() public view returns (uint256) {
        return _deposits[msg.sender];
    }

    function setAdmin(address user) external onlyAdmin {
        address oldAdmin = _admin;
        _admin = user;
        emit SetAdmin(oldAdmin, _admin);
    }

    function totalDeposits() external view onlyAdmin returns (uint256) {
        return _totalDeposits;
    }

    function deposit(uint256 amount) external {
        bool result = token.transferFrom(msg.sender, address(this), amount);
        require(result, TransferFailed(msg.sender));
        _deposits[msg.sender] += amount;
        _totalDeposits += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        uint256 balance = _deposits[msg.sender];
        require(balance >= amount, InsufficientBalance(msg.sender, balance, amount));

        bool result = token.transfer(msg.sender, amount);
        require(result, TransferFailed(msg.sender));

        _deposits[msg.sender] -= amount;
        _totalDeposits -= amount;
        emit Withdraw(msg.sender, amount);
    }
}