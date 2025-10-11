// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract StructDemo {
    // 1. 结构体基础

    // 定义一个简单的结构体
    struct User {
        uint256 id;     // 用户id
        string name;    // 用户名
        uint256 age;    // 年龄
        bool isActive;  // 是否激活
        address wallet; // 钱包地址
    }

    // 定义一个嵌套结构体
    struct Order {
        uint256 id;     // 订单id
        User buyer;    // 买家信息 （嵌套结构体）
        uint256 amount; // 金额
        uint256 timestamp;  // 时间戳
    }

    // 定义一个包含数组的结构体
    struct Product {
        uint256 id;     // 产品id
        string name;    // 产品名称
        uint256 price;  // 价格
        string[] tags;  // 标签数组
        mapping(address => bool) approvedSellers;   // 批准的卖家
    }

    // 2. 结构体的存储

    // 结构体数组
    User[] public users;

    // 结构体映射
    mapping(uint256 => User) public userById;

    // 嵌套结构体数组
    Order[] public orders;

    // 结构体状态变量
    Product public featuredProduct;

    // 3. 结构体初始化方式

    // 方式一、在构造函数中初始化
    constructor() {
        // 使用构造函数初始化
        users.push(User({
            id: 1,
            name: "Alice",
            age: 25,
            isActive: true,
            wallet: address(0x123)  // 0x0000000000000000000000000000000000000123
        }));

        // 使用逐字段赋值
        User memory newUser = User(2, "Bob", 30, true, address(0x456));
        users.push(newUser);

        // 初始化嵌套结构体
        orders.push(Order({
            id: 1001,
            buyer: User(1, "Alice", 25, true, address(0x123)),
            amount: 100,
            timestamp: block.timestamp
        }));

        // 初始化包含动态数组的结构体
        // featuredProduct = Product({
        //     id: 1,
        //     name: "SmartPhone",
        //     price: 999,
        //     tags: ["electronics", "mobile", "premium"]
        //     // approvedSellers: 该字段会自动初始化为空映射
        // });
        featuredProduct.id = 1;
        featuredProduct.name = "SmartPhone";
        featuredProduct.price = 999;
        featuredProduct.tags.push("electronics");
        featuredProduct.tags.push("mobile");
        featuredProduct.tags.push("premium");

    }

    // 4. 结构体的常用操作

    event UserAdded(uint256 _id, string _name);
    // 添加用户
    function addUser(uint256 _id, string calldata _name, uint256 _age, bool _isActive, address _wallet) external {
        // 方式一：直接构造
        // users.push(User(_id, _name, _age, _isActive, _wallet));

        // 方式二：存储在映射中
        // userById[_id] = User(_id, _name, _age, _isActive, _wallet);

        User memory user = User(_id, _name, _age, _isActive, _wallet);
        users.push(user);
        userById[_id] = user;

        emit UserAdded(_id, _name);
    }

    // 更新用户信息
    event UserUpdated(uint256 _id, string _name, uint256 _age);
    function updateUser(uint256 _id, string calldata newName, uint256 newAge) external {
        require(_id != 0, "Invalid user ID");
        require(userById[_id].id != 0, "User not found");  // 先检查用户是否存在，这一步会增加gas消耗
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].id == _id) {
                // 更新结构体字段
                users[i].name = newName;
                users[i].age = newAge;
                userById[_id] = users[i];
                emit UserUpdated(_id, newName, newAge);
                return;
            }
        }        
        // require(false, "User not found");    // 不建议使用 require，因为它会消耗全部剩余gas，这是不必要的
        revert("User not found");   // 不会消耗剩余gas        
    }

    // 获取用户信息
    function getUser(uint256 id) external view returns (User memory) {
        // 从映射中取出
        User memory user = userById[id];
        require(user.id != 0, "User not found");
        return user;
    }

    // 创建订单（嵌套结构体示例）
    event OrderCreated(uint256 id, uint256 buyerId, uint256 amount);
    function createOrder(uint256 userId, uint256 _amount) external {
        // 检查用户是否存在
        User memory buyer = userById[userId];
        require(buyer.id != 0, "User not found");

        Order memory order = Order({
            id: orders.length,
            buyer: buyer,
            amount: _amount,
            timestamp: block.timestamp
        });

        // 创建订单
        orders.push(order);

        emit OrderCreated(order.id, userId, _amount);
    }

    // 获取订单信息
    function getOrder(uint256 orderId) external view returns (Order memory) {
        require(orderId < orders.length, "Order not found");
        return orders[orderId];
    } 

    // 5. 结构体的底层实现

    // 结构体的存储布局示例
    // 在存储中，结构体成员按照声明顺序紧密排列
    // 对于这个User结构体：
    // slot 0: id (uint256)
    // slot 1: name (string的keccak256哈希指针)
    // slot 2: age (uint256)
    // slot 3: isActive (bool, 只占1字节，但占用整个slot)
    // slot 4: wallet (address, 20字节，但占用整个slot)

    // 5. 结构体的适用场景

    // 场景1：用户管理系统
    // 结构体非常适合表示复杂的实体，如用户、产品、订单等

    // 场景2：游戏开发
    struct GameCharacter {
        string name;
        uint256 level;
        uint256 health;
        uint256[] inventory;    // 物品栏
        mapping(uint256 => bool) unlockAchievement;      // 成就系统
    }

    // 场景3：DeFi 协议
    struct LoanPosition {
        address borrower;
        address collateralToken;
        uint256 collateralAmount;
        uint256 borrowedAmount;
        uint256 interestRage;
        uint256 startTime;
        uint256 duration;
    }

    // 7. 结构体常见错误及注意事项

    // 错误1：结构体成员声明顺序不当导致存储空间浪费
    struct InefficientStruct {
        bool flag1;             // 占用整个 slot 32字节
        uint128 value1;         // 占用16 字节，但独占一个 slot
        bool flag2;             // 占用整个 slot
        uint128 value2;         // 占用16字节，但独占一个 slot
        // 总共占用4个slot（128字节），但实际只需要3个slot
    }

    // 错误1修正版：将小型变量放在一起以节省空间
    struct EfficientStruct {
        bool flag1;
        bool flag2;
        uint128 value1;
        uint128 value2;
        // 总共占用 2 个 slot 64字节
    }

    // 错误 2：在 memory 中修改结构体但忘记存储
    // 这个函数展示了一个常见的错误：在 memory 中修改结构体，但忘记将更改保存到 storage
    function incorrectUpdate(uint256 userId, string memory newName) external view {
        // ❌ 错误示例：在 memory 中修改结构体，不会影响 storage
        User memory user = userById[userId];
        require(user.id != 0, "User not found");
        user.name = newName;  // 这个修改仅在 memory 中生效，不会保存到链上
    }

    //  ✅ 错误2修正版：直接修改storage 中的结构体
    function correctUpdate(uint256 userId, string memory newName) external {
        // 直接引用 storage 中的结构体
        User storage user = userById[userId];
        require(user.id != 0, "User not found");

        // 修改 storage 变量，会保存到链上
        user.name = newName;
    }

    // 错误3：直接比较结构体
    function compareUsers(uint256 userId1, uint256 userId2) external view returns (bool) {
        // 这个比较实际是比较的是存储位置，而不是内容
        // return userById[userId1] == userById[userId2];  // 错误！！！

        // 正确做法是逐字段比较
        User memory user1 = userById[userId1];
        User memory user2 = userById[userId2];

        return (
            user1.id == user2.id &&
            keccak256(bytes(user1.name)) == keccak256(bytes(user2.name)) &&
            user1.age == user2.age &&
            user1.isActive == user2.isActive &&
            user1.wallet == user2.wallet
        );
    }

    // 错误4：结构体数组删除元素时处理不当
    function incorrectRemoveUser(uint256 index) external {
        // 错误做法：直接删除会留下空洞
        delete users[index];        
    }

    // 错误4修正版：
    function correctRemoveUser(uint256 index) external {
        // 正确做法：用最后一个元素替换要删除的元素
        require(index < users.length, "Index out of bounds");
        users[index] = users[users.length - 1];
        users.pop();
    }

     /*
    =============================================
    8. 结构体的高级用法
    =============================================
    */

    // 高级用法：结构体与库
    // library UserLibrary {
    //     function isAdult(User memory user) internal pure returns (bool) {
    //         return user.age >= 18;
    //     }

    //     function getUserDescription(User memory user) internal pure returns (string memory) {
    //         return
    //             string(
    //                 abi.encodePacked(
    //                     "User #",
    //                     uint2str(user.id),
    //                     ": ",
    //                     user.name,
    //                     " (",
    //                     user.isActive ? "active" : "inactive",
    //                     ")"
    //                 )
    //             );
    //     }
    // }

    // 高级用法3：结构体与事件
    event UserCreated(uint256 id, string name, uint256 age);

    function createUserWithEvent(
        uint256 id,
        string memory name,
        uint256 age,
        bool isActive,
        address wallet
    ) external {
        users.push(User(id, name, age, isActive, wallet));
        emit UserCreated(id, name, age);
    }

    // 辅助函数：uint256转string
    function uint2str(uint256 number) internal pure returns (string memory) {
        if (number == 0) {
            return "0";
        }
        uint256 temp = number;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        temp = number;
        for (uint256 i = digits; i > 0; i--) {
            buffer[i-1] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }



}