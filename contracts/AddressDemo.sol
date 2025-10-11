// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AddressDemo
 * @dev 示例合约：展示 Solidity 中 address 类型的常用操作
 * @author RemixAI
 */
contract AddressDemo {
    // --- 事件：记录重要操作 ---
    event ReceivedEther(address indexed from, uint amount);
    event SentEther(address indexed to, uint amount);
    event CalledContract(address indexed contractAddr, bool success);

    // --- 状态变量 ---
    // 记录合约所有者（部署者）
    address public owner;
    // 记录最近一次转账的接收地址
    address public lastRecipient;

    /**
    * @dev 构造函数：初始化合约并设置所有者
    * payable 允许合约在部署时接收 ETH
    */
    constructor() payable  {
        owner = msg.sender; // 部署者成为所有者
        emit ReceivedEther(owner, msg.value);   // 记录部署时的ETH 转入
    }

    // 1. 基础地址操作
    /**
    * @dev 获取当前合约地址和余额
    * @return myAddress 合约的地址
    * @return myBalance 合约的余额（wei）
    */
    function getContractInfo() external view returns (address myAddress, uint myBalance) {
        myAddress = address(this);      // this 关键字指当前合约
        myBalance = address(this).balance;  // balance 属性查询 ETH 余额
    }

    /**
    * @dev 检查地址是否为合约地址（即是一个合约账户，不是EOA账户）
    * @param _addr 要检查的地址
    * @return contractOrNot true=合约地址，false=外部账户（EOA）
    *
    * --- 实现原理 ---
    * 在 EVM 中，合约地址和 EOA 地址的区别在于：
    * - EOA（外部账户）：没有字节码，`extcodesize` 返回 0。
    * - 合约地址：部署了字节码，`extcodesize` 返回 > 0。
    *
    * --- 为什么使用 assembly？ ---
    * 1. **气体效率**：直接使用 `extcodesize` 操作码（2600 gas）比 Solidity 的 `address.code.length`（2600 gas + 额外开销）更省气。
    * 2. **准确性**：在合约**构造函数执行期间**，`address.code.length` 可能返回 0（因为字节码尚未完全部署），而 `extcodesize` 仍然可靠。
    *
    * --- 注意事项 ---
    * - 在 **构造函数中**调用此方法检查**自身地址**时，可能返回 false（因为字节码尚未完全部署）。
    * - 对于**预编译合约**（如 `0x01` 到 `0x09`），`extcodesize` 返回 1，但它们不是普通合约。
    * - 避免在**静态调用**（`staticcall`）中使用，因为 `extcodesize` 会被视为“状态修改”操作。
    */
    function isContract(address _addr) external view returns (bool contractOrNot) {
        // --- 内联汇编（Inline Assembly）语法解析 ---
        // 1. `assembly { ... }`：声明内联汇编块，其中可使用 EVM 操作码。
        // 2. `isContract := gt(extcodesize(_addr), 0)`：
        //    - `extcodesize(_addr)`：EVM 操作码，返回 `_addr` 的字节码大小（bytes）。
        //    - `gt(a, b)`：比较 `a > b`，返回 1（true）或 0（false）。
        //    - `:=`：赋值操作符（类似 Solidity 的 `=`，但仅限汇编块内）。
        assembly {
            contractOrNot := gt(extcodesize(_addr), 0)
        }
    } 

    // 2. 转账操作
    /**
    * @dev 使用transfer 发送ETH（2300 gas限制，安全但可能失败）
    * @param _to 接收地址（必须是payable）
    * @param _amount 转账金额（wei）
    */
    function sendViaTransfer(address payable _to, uint _amount) external {
        require(!_isZeroAddress(_to), "Cannot transfer to zero address");
        require(_amount <= address(this).balance, "Insufficient balance");
        // 向 _to 转账 _amount wei
        _to.transfer(_amount);  // 自动抛出错误，2300 gas 限制
        lastRecipient = _to;
        emit SentEther(_to, _amount);
    }

    /**
    * @dev 使用 call 发送 ETH （灵活但需手动检查）
    * @param _to 接收地址
    * @param _amount 转账金额（wei）
    */
    function sendViaCall(address payable _to, uint _amount) external {
        require(!_isZeroAddress(_to), "Cannot transfer to zero address");
        require(_amount <= address(this).balance, "Insufficient balance");
        (bool success, ) = _to.call{value: _amount}("");    // 无gas限制
        require(success, "Transfer failed");
        lastRecipient = _to;
        emit SentEther(_to, _amount);
    }

    /**
    * @dev 使用 sendValue（低级调用，不推荐）
    * @param _to 接收地址
    * @param _amount 转账金额（wei）
    */
    // function sendViaSendValue(address payable _to, uint _amount) external {
    //     require(_amount <= address(this).balance, "Insufficient balance");
    //     bool success = _to.sendValue(_amount);  // 2300 gas 限制，返回布尔类型
    //     require(success, "Transfer failed");
    //     lastRecipient = _to;
    //     emit SentEther(_to, _amount);
    // }

    // 3. 合约交互

    /**
    * @dev 调用其他合约的函数（静态调用）
    * @param _contractAddr 目标合约地址
    * @return result 调用结果（bytes）
    */
    function callStaticFunction(address _contractAddr) external returns (bytes memory result) {
        // 使用 staticcall 调用 view 函数（不修改状态）
        (bool success, bytes memory data) = _contractAddr.staticcall(
            abi.encodeWithSignature("getBalance()")
        );
        require(success, "Static call failed");
        emit CalledContract(_contractAddr, success);
        return data;
    }

    /**
    * @dev 调用其他合约的付费函数（动态调用）
    * @param _contractAddr 目标合约地址
    * @param _value 转账金额（wei）
    */
    function callPayableFunction(address payable _contractAddr, uint _value) external {
        require(_value <= address(this).balance, "Insufficient balance");
        (bool success, ) = _contractAddr.call{value: _value} (
            abi.encodeWithSignature("receiveFunds()")
        );
        require(success, "Call failed");
        emit CalledContract(_contractAddr, success);
    }

    // 4. 接收ETH

    /**
    * @dev 接收 ETH 的回退函数（payable）
    * 当合约直接接收 ETH 时触发（无 calldata)
    */
    receive() external payable {
        require(msg.value > 0, "Cannot receive zero ETH");  // 防止 0 ETH 转账，节省gas和日志存储
        emit ReceivedEther(msg.sender, msg.value);
    }

    /**
    * @dev 接收 ETH 的 fallback 函数（payable）
    * 当调用不存在的函数时触发
    */
    fallback() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }

    // 5. 安全检查

    /**
    * @dev 检查地址是否为零地址，仅限合约内部调用，可以降低gas 开销。
    * 但仍比不上直接内联比较（即 _to == address(0) 仅开销3 gas），
    * interal 函数调用约 30 gas
    */
    function _isZeroAddress(address _addr) internal pure returns (bool) {
        return _addr == address(0);
    }

    /**
    * @dev 检查地址是否为零地址（防止以为烧毁资金），不能用于合约内部调用，
    * 因 gas 开销太高，合约内部调用 external 函数，会消耗约 700 gas。
    * @param _addr 要检查的地址
    * @return isZero true=零地址，false=有效地址
    */
    function isZeroAddress(address _addr) external pure returns (bool isZero) {
        return _addr == address(0);
    }

    // 6. 实用工具

    /**
    * @dev 将地址转换为 payable 地址（显式转换）
    * @param _addr 原始地址
    * @return payableAddr payable 类地址
    */
    function toPayable(address _addr) external pure returns (address payable payableAddr) {
        return payable(_addr);
    }

    /**
    * @dev 比较两个地址是否相等
    * @param _addr1 地址1
    * @param _addr2 地址2
    * @return isEqual true=相等，false=不相等
    */
    function compareAddresses(address _addr1, address _addr2) external pure returns (bool isEqual) {
        return _addr1 == _addr2;
    }

    /**
    * @dev 展示 msg 的用法
    */
    function showMsgDetails() external payable returns (address sender, uint value, bytes4 funcSelector) {
        sender = msg.sender;
        value = msg.value;
        funcSelector = msg.sig;     // 前4字节 = 函数选择器
    }

}