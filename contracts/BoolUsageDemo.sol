// 声明合约的开源许可证，明确代码的使用权限和责任限制
// 区块链项目通常要求开源，许可证是法律保障
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;    // 0.8.x的关键特性：默认启用算术自动检查溢出（无需SafeMatch）；引入override 关键字，自定义错误等。

/**
 * @title 布尔类型使用示例
 * @dev 示范 Solidity 中 bool 类型的声明、修改、逻辑运算和安全模式
 * @notice 适合初学者：包含状态变量、函数修饰器、事件和安全检查
 */
contract BoolUsageDemo {    // contract：定义一个智能合约，类似于类Class；部署后成为区块链上的独立账户（合约账户），有地址，有余额
    // --- 状态变量（State Variables）---
    // 这些变量永久存储在区块链上，修改它们需要消耗 Gas。
    // 布尔类型默认值为 `false`，占用 1 个存储槽（但优化后可能与其他变量打包），一个存储槽32字节

    // `public` 关键字自动生成一个同名的 getter 函数，外部合约可以读取它。
    // 状态变量的初始化只在合约部署时执行一次。
    bool public isPaused;   // 默认为false，表示合约未暂停
    bool public isOwner = true;     // 初始化为true，假设部署者是所有者
    bool private _internalFlag;     // 私有变量，仅合约内部可访问

    // 创建一个映射：用户地址到ETH的映射
    mapping(address => uint256) public userBalances;   // 状态变量，用于存储用户的余额
    uint256 public totalDeposited = 0; // 状态变量，用于存储总存款金额
    uint public sumOfUsers = 0; // 状态变量，用于存储用户数量

    // 复杂布尔逻辑示例：多个条件组合
    bool public isReady = false;
    bool public isConfigured = true;
    bool public isApproved;

    // --- 事件（Events）---
    // 事件用于记录合约执行过程中的重要操作（相当于日志），
    // 作用：
    // 1、前端（如Ether.js）可以监听这些事件，并据此执行某些操作，如更新UI等。
    // 2、区块链浏览器（如Etherscan）展示事件历史。

    // 事件：用于记录布尔值的变化
    event BoolStateChanged(
        string indexed stateName,  // indexed：索引参数，便于前端过滤（如使用filter）
        bool newValue,
        address changer            // 谁触发了变化
    );

    event ActionExecuted(
        string actionName,
        bool success,
        string message
    );

    event Deposit(
        address user,
        uint256 amount
    );

    // --- 修饰器（Modifiers）---
    // 修饰器作用：定义函数前检查逻辑，类似装饰器。
    // 用途：
    // 1、控制函数访问（如暂停机制，权限检查等）
    // 2、避免重复代码（如只需给函数添加上 onlyOwner 修饰器，就可以给所有添加该修饰器的函数执行是否所有者的检查）

    // 使用布尔变量控制函数访问
    /** @dev 仅在合约未暂停时可调用 */
    modifier whenNotPaused() {
        // require(...)：若 isPaused 为 true，抛出错误并回退。
        require(!isPaused, "BoolUsageDemo: Contract is paused");
        _;  // 继续执行被修饰的函数
    }

    /** @dev 仅所有者可调用（简化示例，实际项目应使用 OpenZeepelin Ownable）*/
    modifier onlyOwner() {
        require(isOwner, "BoolUsageDemo: Not owner");
        _;
    }

    // --- 函数（Functions）---

    /** @dev 切换暂停状态（所有者专用）*/
    function togglePause() external onlyOwner {     // 这里应用了 onlyOwner 修饰器
        // external：仅允许外部调用，即在合约内部不可直接调用。
        isPaused = !isPaused;
        // emit event_name(...)：触发事件，并将数据写入【区块链日志】。
        // 事件存储在【交易日志】中会有Gas消耗，但成本低于存储变量。
        emit BoolStateChanged("isPaused", isPaused, msg.sender);
    }

    /** @dev 设置内部标志：示范私有变量修改 */
    function setInternalFlag(bool newValue) external {
        _internalFlag = newValue;
        emit BoolStateChanged("internalFlag", newValue, msg.sender);
    }

    /** 
    * @dev 复杂布尔逻辑示例：检查多个条件
    * @notice 使用 `&&`（与）、`||`（或）、`!`（非）运算符
    */
    function checkReadiness() external whenNotPaused returns (bool) {   // returns (bool)：声明返回一个布尔值
        // 条件1：已配置 AND 未暂停
        bool condition1 = isConfigured && !isPaused;
        // 条件2：已批准 or 内部标志为真
        bool condition2 = isApproved || _internalFlag;

        bool result = condition1 && condition2;
        emit ActionExecuted("checkReadiness", result, "Complex bool logic check");
        return result;
    }

    /** @dev 安全示例：防止重入攻击的布尔锁 */
    bool private _locked;

    function safeAction() external whenNotPaused {
        // 检查 _locked 是否为false，如果不是，说明已被锁上，返回报错信息。
        require(!_locked, "BoolUsageDemo: Reentrancy guard");
        _locked = true;     // 上锁

        // 模拟状态变更（例如转账逻辑）
        isReady = true;
        emit BoolStateChanged("isReady", isReady, msg.sender);

        _locked = false;    // 解锁
    }

    // --- 查看函数（View Functions）---
    // view关键字：声明函数不修改状态，不消耗GAS
    // 函数仅读取状态变量，或者调用其他 view/pure 函数

    // 不修改状态，无 Gas 消耗
    /** @dev 返回私有变量值（示范内部状态暴露）*/
    function getInternalFlag() external view returns (bool) {
        return _internalFlag;
    }

    /** @dev 示范三元运算符：简洁条件判断 */
    function getStatusMessage() external view returns (string memory) {   // memory：指定返回字符串的存储位置，memory是临时内存非持久存储。  
        return isPaused ? "Contract is paused" : "Contract is active";
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    function receiveFunds() external payable {
        require(!_locked, "BoolUsageDemo: Reentrancy guard");
        require(msg.value > 0, "BoolUsageDemo: Amount must be greater than zero");
        _locked = true;
        userBalances[msg.sender] += msg.value;
        totalDeposited += msg.value;
        sumOfUsers += 1;
        emit Deposit(msg.sender, msg.value);
        _locked = false;
    }

    receive() external payable {
        require(!_locked, "BoolUsageDemo: Reentrancy guard");
        _locked = true;
        emit Deposit(msg.sender, msg.value);
        _locked = false;
     }

    
    function addressToString(address _addr) public pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(_addr);
        bytes memory hexString = new bytes(42); // 0x + 20 bytes * 2 chars per byte

        hexString[0] = '0';
        hexString[1] = 'x';

        for (uint256 i = 0; i < 20; i++) {
            hexString[2 + i * 2] = _toHexDigit(uint8(addressBytes[i] >> 4));
            hexString[3 + i * 2] = _toHexDigit(uint8(addressBytes[i] & 0x0f));
        }

        return string(hexString);
    }

    function _toHexDigit(uint8 nibble) private pure returns (bytes1) {
        if (nibble < 10) {
            return bytes1(uint8(bytes1('0')) + nibble);
        } else {
            return bytes1(uint8(bytes1('a')) + nibble - 10);
        }
    }
}