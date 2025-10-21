// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Bank.sol";

contract BigBank is Bank {
    uint256 public limit = 1000000000000000;

    modifier greaterThan() {
        require(msg.value > limit, "Amount must be greater than 1000000000000000 wei");
        _;
    }

    function deposit() public payable override greaterThan {
        super.deposit();
    }

    receive() external override  payable { 
        // 注意：不能写成 this.deposit() 外部调用形式！！！！！
        // 否则 msg.value 将被清零！！！！！
        deposit();
    }

    event withdrawFromBigBank(address indexed who, uint256 amount);
    function withdraw(uint256 amount) public override {
        super.withdraw(amount);
        emit withdrawFromBigBank(msg.sender, amount);
    }


}

contract Admin {
    BigBank bigBank;
    address private admin;

    constructor() {
        bigBank = new BigBank();
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    function getAdmin() external view returns (address) {
        return admin;
    }

    event withdrawFromAdmin(address indexed who, uint256 amount);
    function withdraw(uint256 amount) external onlyAdmin {
        bigBank.withdraw(amount);
        emit withdrawFromAdmin(msg.sender, amount);
    }
}