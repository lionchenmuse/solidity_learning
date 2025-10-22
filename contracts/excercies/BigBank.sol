// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Bank.sol";

contract BigBank is Bank {
    // 0.001 ETH
    uint256 public limit = 1000000000000000;

    constructor() Bank() {}

    modifier greaterThan() {
        // 必须大于 0.001 ETH
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

    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    /// @dev 可以重新设置管理员
    function setAdmin(address _admin) external onlyAdmin {
        address oldAdmin = admin;
        admin = _admin;
        emit AdminChanged(oldAdmin, admin);
    }


}

contract Admin {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    event WithdrawFromAdminSuccess();
    function adminWithdraw(IBank bank) external onlyOwner {
        bank.withdraw(123); // 随便填一个数，BigBank 会将全部资金转移给 Admin合约（因为重置了BigBank的管理员）
        emit WithdrawFromAdminSuccess();
    }

    receive() external payable { }
}