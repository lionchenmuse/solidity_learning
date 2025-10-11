// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Bank is ReentrancyGuard {
    

    struct Account {
        address user;
        uint256 amount;
    }

    // address[] private addresses;
    mapping (address => uint256) private balances;
    // mapping (address => bool) _members;
    Account[3] public top3;

    address private admin;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _members;

    constructor() {
        admin = msg.sender;
        // 初始化 top3
        for (uint i = 0; i < 3; i++) {
            top3[i] = Account({user: address(0), amount: 0});
        }
    }

    event ReceiveEvent(address indexed sender, uint256 amount, uint256 total);
    receive() external payable {
        require(msg.sender != address(0), "Bank: zero address");
        require(msg.value != 0, "Bank: zero amount");

        uint256 total = balances[msg.sender] + msg.value;
        calcTop3(total);

        balances[msg.sender] = total;

        if (!_members.contains(msg.sender)) {
            _members.add(msg.sender);
        }
        
        emit ReceiveEvent(msg.sender, msg.value, total);
    }

    function getBalance(address _address) external view returns (uint256) {
        require(_address != address(0), "Bank: zero address");
        return balances[_address];
    }

    function getAdmin() external view returns (address) {
        return admin;
    }

    function withdraw(uint256 amount) external nonReentrant {
        if (msg.sender != admin) {
            require(amount <= balances[msg.sender], "Insufficient balance");
            balances[msg.sender] -= amount;

            // 重新计算排名
            calcTop3WhenWithdrawing();

            // 当某人存款金额为0时，将他从地址数组中剔除，并剔除其成员资格
            if (balances[msg.sender] == 0) {
                for (uint256 i = 0; i < _members.length(); i++) {
                    if (_members.at(i) == msg.sender) {
                        _members.remove(msg.sender);
                        break;
                    }
                }
            }

            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed");
        } else {
            uint256 total = 0;
            for (uint256 i = 0; i < _members.length(); i++) {
                total += balances[_members.at(i)];    // 严重安全风险：管理员清空所有用户余额
                balances[_members.at(i)] = 0;
            }
            (bool success, ) = admin.call{value: total}("");
            require(success, "Transfer to admin failed");
        }   
        // 缺少事件记录，无法追踪资金流向    
        // 链上分析工具（如 Etherscan）无法记录管理员操作
    }

    // 计算排名
    function calcTop3(uint256 total) private {
        if (total > top3[0].amount) {
            top3[2] = top3[1];
            top3[1] = top3[0];
            top3[0].user = msg.sender;
            top3[0].amount = total;
        } else if (total > top3[1].amount) {
            top3[2] = top3[1];
            top3[1].user = msg.sender;
            top3[1].amount = total;
        } else if (total > top3[2].amount) {
            top3[2].user = msg.sender;
            top3[2].amount = total;
        }
    }

    function calcTop3WhenWithdrawing() private {
        // 第一步，判断是否影响排名，即取款人如果是top3成员，取款后，是否会出现新的top3
        uint256 remainingAmount = balances[msg.sender];
        if (msg.sender == top3[0].user) {   // 如果是第一名取款
            if (remainingAmount > top3[1].amount) { // 但取款后的剩余金额依然超过第二名，则只更新第一名的余额后返回
                top3[0].amount = remainingAmount;
                return;     // 不影响排名，返回
            } else if (remainingAmount > top3[2].amount) {  // 如果第一名取款后的余额只是高于原第三名，则将原第二名提到第一名，原第一名改为第二名
                top3[0] = top3[1];
                top3[1].user = msg.sender;
                top3[1].amount = remainingAmount;
                return;     // 未出现新top3，返回
            } else if (remainingAmount == top3[2].amount) { // 如果第一名取款后的余额和原第三名相等，则将第二和第三名分别提高一位，原第一名改为第三名
                top3[0] = top3[1];
                top3[1] = top3[2];
                top3[2].user = msg.sender;
                top3[2].amount = remainingAmount;
                return;    // 未出现新top3，返回  
            } else {    // 如果第一名取款后，余额小于第三名则将第二和第三名分别提高一位，新的第三名置空，后续待循环处理
                top3[0] = top3[1];
                top3[1] = top3[2];
                top3[2].user = address(0);
                top3[2].amount = 0;                 // 可能出现新top3，后续迭代找出后，填入
            }
        }

        if (msg.sender == top3[1].user) {   // 如果是第二名取款
            if (remainingAmount > top3[2].amount) { // 但取款后的剩余金额依然超过第三名，则只更新第二名的金额后返回
                top3[1].amount = remainingAmount;
                return;     // 不影响排名，返回
            } else if (remainingAmount == top3[2].amount) {     // 如果第二名取款后的剩余金额和原第三名相等，则将原第三名提高一位，原第二名改为第三名
                top3[1] = top3[2];
                top3[2].user = msg.sender;
                top3[2].amount = remainingAmount;
                return;         // 未出现新top3，返回
            } else {    // 如果第二名取款后，余额小于第三名，则将原第三名提高一位，新的第三名置空，后续待循环处理
                top3[1] = top3[2];
                top3[2].user = address(0);
                top3[2].amount = 0;         // 可能出现新top3，后续迭代找出后，填入
            }          
        }

        if (msg.sender == top3[2].user) {   // 如果是第三名取款，则将第三名置空，后续待循环处理
            top3[2].user = address(0);
            top3[2].amount = 0;         // 可能出现新top3，后续迭代找出后，填入
        }

        // 第二步，迭代 _members，从中找出新的top3成员，填充到top3数组
        for (uint256 i = 0; i < _members.length(); i++) {
            address member = _members.at(i);            

            if (member == top3[0].user || member == top3[1].user || member == address(0)) {
                continue;
            }
            uint256 amount = balances[member];

            if (amount > top3[2].amount) {
                if (amount > top3[0].amount) {
                    top3[2] = top3[1];
                    top3[1] = top3[0];
                    top3[0].user = member;
                    top3[0].amount = amount;
                } else if (amount > top3[1].amount) {
                    top3[2] = top3[1];
                    top3[1].user = member;
                    top3[1].amount = amount;
                } else if (amount > top3[2].amount) {
                    top3[2].user = member;
                    top3[2].amount = amount;
                }
            }
            
        }
       
    }

}