// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
* @title MappingDemo
* @dev 演示 solidity 映射的用法、注意事项及底层原理
*/
contract MappingDemo {
    uint256 private constant MAX_ALLOWANCE = 100000000000000;

    // ----- 1. 基本映射声明 -----
    // 语法：`mapping(keyType => valueType)[Visibility] MappingName;`
    // - KeyType: 可以是任何内置值类型（uint, address, bytes等），但不能是自定义结构体或映射。
    // - ValueType: 可以是任何类型（包括结构体或映射）。
    // - 可见性: 默认 `internal`，可以显式设为 `public`（自动生成 getter）。

    // 示例1：address => uint：常用于余额记录
    mapping(address => uint256) public balances;

    // 示例2：uint => 结构体（复杂数据）
    struct User {
        string name;
        uint256 age;
        bool isActive;
    }
    mapping(uint256 => User) public users;

    // 示例3：嵌套映射
    mapping(address => mapping(address => uint256)) public allowances;

    // ----- 2. 初始化与访问 -----

    event UserSet(uint256 indexed id, string name, uint256 age);
    /**
    * @dev 设置用户信息
    * @param id 用户id
    * @param _name 用户名
    * @param _age 年龄
    */
    function setUser(uint256 id, string calldata _name, uint256 _age) external {
        User storage user = users[id];
        user.name = _name;
        user.age = _age;

        emit UserSet(id, _name, _age);
    }

    event BalanceUpdated(address indexed _account, uint256 _amount);
    /**
    * @dev 更新余额
    * @param _account 地址
    * @param _amount 余额
    */
    function updateBalance(address _account, uint256 _amount) external {
        require(_account != address(0), "The account address is ZERO!");
        balances[_account] = _amount;
        emit BalanceUpdated(_account, _amount);
    }

    event AllowanceGranted(address owner, address spender, uint256 amount);
    event AllowanceUpdated(address owner, address spender, uint256 oldAmount, uint256 newAmount);
    /**
    * @dev 设置授权额度（支持检查和事件拆分）
    * @param _owner 所有者地址（非零）
    * @param _spender 被授权地址（非零）
    * @param _amount 额度（0 = 取消授权）
    */
    function setAllowance(
        address _owner,
        address _spender,
        uint256 _amount
    ) external {
        require(_owner != address(0), "Owner cannot be ZERO");
        require(_spender != address(0), "Spender cannot be ZERO");
        require(_amount <= MAX_ALLOWANCE, "Amount exceeds max allowance"); // 可选：上限检查

        // Solidity 的 mapping 没有“存在性”概念。任何 key 访问都会返回类型的默认值（uint256 为 0）。
        // 直接赋值 allowances[_owner][_spender] = _amount 会：
        // - 如果 (_owner, _spender) 组合不存在，则创建该键值对并赋值。
        // - 如果已存在，则覆盖原值。
        uint256 oldAmount = allowances[_owner][_spender];
        allowances[_owner][_spender] = _amount;

        if (oldAmount == 0 && _amount > 0) {
            emit AllowanceGranted(_owner, _spender, _amount);
        } else if (oldAmount != _amount) {
            emit AllowanceUpdated(_owner, _spender, oldAmount, _amount);
        }
    }

    // ----- 3. 易犯错误和注意事项 -----

    /** ❌ 错误1: 尝试初始化映射（编译报错）: 不支持内联初始化映射 */
    // mapping(address => uint256) public initalizedBalances = {0x123...: 100};

    /** ❌ 错误2: 使用未初始化的映射键（默认值） */
    function getUninitializedBalance(address _account) external view returns (uint256) {
        // 映射中不存在的键返回类型的默认值（uint256: 0, bool: false, address: 0x0）
        return balances[_account];      // 如果 `account` 未设置过，返回 0
    }

    /** ❌ 错误3: 忽略映射的存储位置 */
    // 映射只能存储在 `storage` 中，不能用于 `memory` 或作为函数参数/返回值。
    // function badFunction(mapping(address => uint256) memory badMap) external {}  // 编译报错

    /** ⚠️ 注意1: 映射的 gas 成本 */
    // - 读取映射：~2100 gas（SLOAD）
    // - 写入映射：~20000 gas（SSTORE，首次写入更高）
    // - 嵌套映射的 gas 成本更高（每层增加 SLOAD/SSTORE）

    /** ⚠️ 注意2: 映射的存储槽（Storage Slot） */
    // 映射的值存储在 `keccak256(h(key) . p)` 计算的槽位，其中：
    // - `h(key)`: key 的紧凑编码（abi.encodePacked(key)）
    // - `p`: 映射在合约存储中的起始槽位（编译器分配）
    // 示例：`balances[0x123]` 的存储位置：
    // slot = uint256(keccak256(abi.encodePacked(0x123), balances 的槽位))

    // --- 4. 高级用法: 动态数组 + 映射模拟 "可遍历映射" ---
    address[] private _users;   // 存储所有用户地址
    mapping(address => bool) private _userExists;   //记录用户是否存在

    function addUser(address user) external {
        if (!_userExists[user]) {
            _users.push(user);
            _userExists[user] = true;
        }
    }

     // --- 5. 与 Java Map 的对比 ---
    /*
    | 特性               | Solidity `mapping`          | Java `HashMap`               |
    |--------------------|----------------------------|-----------------------------|
    | 初始化             | 不支持                     | 支持（`new HashMap()`）      |
    | 遍历               | 不支持（需辅助结构）       | 支持（`entrySet()`/`keySet()`）|
    | 键类型限制         | 值类型（uint/address等）   | 任意对象（需实现 `hashCode`）|
    | 默认值             | 类型默认值（0/false/0x0）   | `null`                      |
    | 内存存储           | 仅 `storage`               | 堆内存（`Heap`）             |
    | gas 成本           | 高（SLOAD/SSTORE）          | 低（内存操作）              |
    | 嵌套支持           | 支持                       | 支持（`Map<K, Map<K, V>>`）  |
    */

}