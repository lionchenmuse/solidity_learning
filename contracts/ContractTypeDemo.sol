// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- 接口定义（用于合约类型变量，注意：必须定义在合约外部）---
interface IERC20 {
    function transfer(address to, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
}

// 简单合约（用于部署示例，也必须定义在合约外部）
contract SimpleStorage {
    uint public storedData;
    function set(uint x) external {
        storedData = x;
    }
    function get() external view returns (uint) {
        return storedData;
    }
}

/**
* @title ContractTypeDemo
* @dev 示例合约：展示Solidity中合约类型的用法、与地址类型的关系，及常见错误
*/
contract ContractTypeDemo {
    // --- 事件：记录关键操作 ---
    event ContractCalled(address indexed contractAddr, string functionName, bool success);
    event ContractCreated(address indexed newContract, string contractName);
    event TypeConversion(address original, address payable converted, address contractType);

    // --- 状态变量 ---
    // 1. 合约类型变量：通过接口或合约名声明
    //    - 与 `address` 的区别：合约类型变量绑定了ABI， 可直接调用其函数
    //    - 与 `address` 的相同点：底层仍是20 字节地址，可相互转换
    IERC20 public tokenContract;    // 接口类型变量
    SimpleStorage public storageContract;   // 具体合约类型变量

    // 2. 地址类型变量（对比用）
    address public genericAddress;
    address payable public payableAddress;

    // --- 构造函数：初始化示例 ---
    constructor() {
        // 初始化地址变量（非合约类型）
        genericAddress = address(this);
        payableAddress = payable(address(this));
    }

    // ===== 1. 合约类型的基础用法 =====

    /**
     * @dev 设置合约类型变量（通过地址显式转换）
     * @param _tokenAddr ERC20 代币合约地址
     * @param _storageAddr SimpleStorage 合约地址
     *
     * --- 关键点 ---
     * 1. 合约类型变量**必须**通过显式转换（`ContractType(address)`）赋值
     * 2. 转换前应检查地址是否为合约（避免调用非合约地址）
     * 3. 转换不改变底层地址，只添加 ABI 信息
     */
    function setContracts(address _tokenAddr, address _storageAddr) external  {
        // 安全检查：确保地址是合约
        require(isContract(_tokenAddr), "Not a contract: token");
        require(isContract(_storageAddr), "Not a contract: storage");

        // 显式转换：address → 合约类型
        tokenContract = IERC20(_tokenAddr);
        storageContract = SimpleStorage(_storageAddr);

        emit TypeConversion(_tokenAddr, payable(_tokenAddr) , address(tokenContract));
    }

    // 2. ===== 合约类型 vs 地址类型 =====

     /**
     * @dev 展示合约类型与地址类型的相互转换
     *
     * --- 转换规则 ---
     * 1. 合约类型 → address：隐式转换（自动）
     *    - `address(tokenContract)`直接赋值给 `address` 变量
     * 2. address → 合约类型：显式转换（需 `ContractType(addr)`）
     * 3. 合约类型 → payable address：先转为 `address`，再转为 `payable`
     *
     * --- 注意 ---
     * - 转换不改变底层地址，只改变“视图”（ABI 信息）
     * - 转换不检查目标地址是否真实存在合约（需手动验证）
     */
     function demonstrateTypeConversions() external {
        // 1. 合约转地址：显式转换
        address tokenAsAddress = address(tokenContract);
        address storageAsAddress = address(storageContract); 

        // 2. 地址转合约：显式转换
        IERC20 tokenFromAddress = IERC20(tokenAsAddress);
        SimpleStorage storageFromAddress = SimpleStorage(storageAsAddress);

        // 3. 合约转 payable 地址：两步转换
        address payable tokenAsPayable = payable(address(tokenContract));

        // 触发事件记录日志
        emit TypeConversion(tokenAsAddress, tokenAsPayable, address(tokenFromAddress));
     }

     // 3. ===== 调用合约函数 =====
    /**
     * @dev 通过合约类型变量调用其他合约
     * @param _to 接收代币的地址
     * @param _amount 转账数量
     *
     * --- 优势 ---
     * 1. 类型安全：编译器检查函数签名
     * 2. 代码可读性高：`tokenContract.transfer(...)` 明确意图
     * 3. 自动编码/解码：无需手动 `abi.encode`
     *
     * ---：使用 `address.call` ---
     * - 需手动编码：`abi.encodeWithSignature("transfer(address,uint256)", _to, _amount)`
     * - 无类型检查：容易传错参数
     */
     function callTokenTransfer(address _to, uint _amount) external {
        require(address(tokenContract) != address(0), "Token contract not set");
        require(tokenContract.balanceOf(address(this)) >= _amount, "Insufficient balance");

        // 直接调用（类型安全）
        bool success = tokenContract.transfer(_to, _amount);
        require(success, "Transfer failed");

        emit ContractCalled(address(tokenContract), "transfer", success);
     }

     /**
     * @dev 调用SimpleStorage 的 set 函数
     * @param _value 要存储的值
     */
     function callStorageSet(uint _value) external {
        require(address(storageContract) != address(0), "Storage contract not set");
        storageContract.set(_value);    // 直接调用
        emit ContractCalled(address(storageContract), "set", true);
     }

     // 4. ===== 部署合约 =====

     /**
     * @dev 部署新的 SimpleStorage 合约
     * @param _initialValue 初始存储值
     *
     * --- 关键点 ---
     * 1. 使用 `new ContractName()` 部署合约
     * 2. 构造函数参数（如有）在括号内传入
     * 3. 返回值为新合约的地址（`address` 类型）
     * 4. 部署合约会消耗大量 gas（取决于合约大小）
     */
     function deployStorageContract(uint _initialValue) external {
        SimpleStorage newContract = new SimpleStorage();
        newContract.set(_initialValue); // 调用新合约的函数

        // 记录新合约的地址
        storageContract = newContract;
        emit ContractCreated(address(newContract), "SimpleStorage");
     }

     // 5. ===== 低级调用 =====

     /**
     * @dev 使用 `address.call` 调用合约（低级方法）
     * @param _contractAddr 目标合约地址
     * @param _to 接收代币的地址
     * @param _amount 转账数量
     *
     * --- 风险 ---
     * 1. 无类型检查：容易传错函数选择器或参数
     * 2. 需手动解码返回值（如有）
     * 3. 容易忽略返回值（`success`）
     *
     * --- 何时使用？---
     * - 调用**动态接口**（运行时确定函数签名）
     * - 与**非 Solidity 合约**交互（如预编译合约）
     */
     function callTokenTransferLowLevel(address _contractAddr, address _to, uint _amount) external {
        // 手动编码调用数据   
        bytes memory payload = abi.encodeWithSignature(
            "transfer(address, uint256)",
            _to,
            _amount
        );
        // 低级调用（无类型安全保障）
        (bool success, bytes memory data) = _contractAddr.call(payload);
        require(success, "Low-level call failed");

        // 手动解码返回值（如果有）
        bool transferSuccess = abi.decode(data, (bool));

        emit ContractCalled(_contractAddr, "transfer (low-level)", transferSuccess);
     }

     // 6. ===== 常见错误及防范 =====

      /**
     * @dev 展示常见错误：未检查合约地址是否为零
     * @param _contractAddr 合约地址（可能为零）
     *
     * --- 错误 ---
     * 1. 未检查 `_contractAddr` 是否为零地址
     * 2. 直接转换零地址为合约类型 →会失败（但不会 revert）
     *
     * --- 修复 ---
     * 总是检查地址是否为零：
     * `require(_contractAddr != address(0), "Zero address");`
     */
    function unsafeContractConversion(address _contractAddr) external {
        // ❌ 不安全：未检查零地址
        IERC20 unsafeToken = IERC20(_contractAddr);

        // 调用零地址会静默失败（但不 revert）
        bool success = unsafeToken.transfer(msg.sender, 0);
        // `success` 可能为 false，但不会抛出错误！

        emit ContractCalled(_contractAddr, "unsafe transfer", success);
    }

    /**
     * @dev 展示常见错误：假设地址是合约但实际不是
     * @param _addr 可能不是合约的地址
     *
     * --- 错误 ---
     * 1. 未验证 `_addr` 是否真实部署了合约
     * 2. 对 EOA 调用合约函数 → 失败（但可能不 revert）
     *
     * --- 修复 ---
     * 使用 `isContract()` 检查（见下方实现）
     */
    function unsafeContractAssumption(address _addr) external {
        // ❌ 不安全：假设 _addr 是合约
        SimpleStorage assumedStorage = SimpleStorage(_addr);

        // 对 EOA 调用会失败（但可能不 revert）
        assumedStorage.set(42);  // 静默失败

        emit ContractCalled(_addr, "unsafe assumption", false);
    }

    // 7. ===== 工具函数 =====

    /**
    * @dev 检查地址是否为合约
    * @param _addr 要检查的地址
    * @return true=合约，false=EOA 或不存在
    */
    function isContract(address _addr) public view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }



    
}