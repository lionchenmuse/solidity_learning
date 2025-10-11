// SPDX-License-Identifier: MIT
// pragma solidity ^0.7.6;      // 如果用 0.7版本，要添加：pragma abicoder v2;
// pragma abicoder v2;
pragma solidity ^0.8.20;

contract ArrayDemo {
    // 1. 状态变量中的数组

    // 定长数组
    uint256[5] public fixedArray;
    // 动态数组：长度可变
    uint256[] public dynamicArray;

    // 动态结构体数组
    struct Product {
        uint256 id;
        string name;
        uint256 price;
    }
    Product[] public products;

    // 映射中的动态数组
    mapping(address => uint256[]) public userOrders;

    // 二维数组（固定和动态组合）
    uint256[3][] public matrix;

    // 2. 数组初始化

    // 在构造函数中初始化数组
    constructor() {
        // 初始化定长数组
        fixedArray = [1,2,3,4,5];

        // 初始化动态数组
        dynamicArray.push(10);
        dynamicArray.push(20);
        dynamicArray.push(30);

        // 初始化结构体数组
        products.push(Product(1, "Laptop", 1000));
        // 以下代码报错：不能在push方法中使用“{...}”初始化结构体
        // products.push(Product{id: 2, name: "Phone", price: 800});
        products.push(Product(2, "Phone", 800));

        // 初始化映射中的数组
        userOrders[msg.sender].push(1001);
    }

    modifier checkIndexOutOfBounds(uint256 index, uint256 arrayLength) {
        require(index < arrayLength, "Index out of bounds");
        _;
    }

    // 3. 定长数组示例
    // 更新定长数组元素
    function updateFixedArray(uint256 index, uint256 value) external checkIndexOutOfBounds(index, fixedArray.length) {
        fixedArray[index] = value;
    }

    // 获取定长数组元素
    function getFixedArrayElement(uint _index) external view checkIndexOutOfBounds(_index, fixedArray.length) returns (uint256) {
        return fixedArray[_index];
    }

    // 4. 动态数组示例

    // 添加元素到动态数组
    function addToDynamicArray(uint256 value) external {
        dynamicArray.push(value);
    }

    // 从动态数组中移除元素
    function removeFromDynamicArray(uint256 _index) external checkIndexOutOfBounds(_index, dynamicArray.length) {
        // 将最后一个元素移到被删除的位置
        dynamicArray[_index] = dynamicArray[dynamicArray.length - 1];
        // 删除最后一个元素
        dynamicArray.pop();

        // 这样做的原因是：如果直接将某个位置的元素删除，其右侧所有元素都会向左移动一位，
        // 造成大量的赋值操作，耗费大量gas。
    }

    // 更新动态数组元素
    function updateDynamicArray(uint256 index, uint256 value) external checkIndexOutOfBounds(index, dynamicArray.length) {
        dynamicArray[index] = value;
    }

    // 获取动态数组长度
    function getDynamicArrayLength() external view returns (uint256) {
        return dynamicArray.length;
    }

    // 获取动态数组某个元素
    function getDynamicArrayByIndex(uint256 _index) external view checkIndexOutOfBounds(_index, dynamicArray.length) returns (uint256) {
        return dynamicArray[_index];
    }

    // 5. 结构体数组示例

    // 添加产品
    function addProduct(uint256 id, string calldata name, uint256 price) external {
        products.push(Product(id, name, price));
    }

    // 更新产品
    function updateProduct(uint256 _idx, uint256 _id, string memory name, uint256 price) 
        external checkIndexOutOfBounds(_idx, products.length) {

        products[_idx] = Product(_id, name, price);
    }

    // 获取产品
    function getProduct(uint256 _idx) external view checkIndexOutOfBounds(_idx, products.length) returns (Product memory) {
        return products[_idx];
    }

    // 6. 映射中的数组示例
    // 添加用户订单
    function addUserOrder(uint256 orderId) external {
        userOrders[msg.sender].push(orderId);
    }

    // 获取用户订单
    function getUserOrders(address user) external view returns (uint256[] memory) {
        return userOrders[user];
    }

    // 7. 数组遍历示例

    // 计算动态数组中所有元素的和
    function sumDynamicArray() external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < dynamicArray.length; i++) {
            total += dynamicArray[i];
        }
        return total;
    }

    // 计算产品数组的总价格
    function totalProductsPrice() external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < products.length; i++) {
            total += products[i].price;
        }
        return total;
    }

    // 8. 高级数组操作

    // 删除数组中特定值的所有实例
    function removeAllInstances(uint256 value) external {
        for (uint256 i = 0; i < dynamicArray.length; ) {
            if (dynamicArray[i] == value) {
                // 将最后一个元素移动到当前位置
                dynamicArray[i] = dynamicArray[dynamicArray.length - 1];
                // 删除最后一个元素
                dynamicArray.pop();
                // 不增加i，因为新元素需要检查
            } else {
                i++;
            }
        }
    }

    // 数组排序：简单冒泡排序
    function sortDynamicArray() external {
        for (uint256 i = 0; i < dynamicArray.length - 1; i++) {
            bool swapped = false;
            for (uint256 j = 0; j < dynamicArray.length - i - 1; j++) {
                if (dynamicArray[j] > dynamicArray[j+1]) {
                    // 交换元素
                    (dynamicArray[j], dynamicArray[j+1]) = (dynamicArray[j+1], dynamicArray[j]);
                    swapped = true;
                }
            }
            if (!swapped) break; // 如果没有交换，数组已经排序
        }
    }

    // 9. 数组切片：0.8.20+

    // 获取数组的子数组
    function getSubArray(uint256 start, uint256 length)  // 该函数返回了一个动态内存数组，编译器会要求使用 abicoder v2 进行编码（更高效，成本更低）
        external view checkIndexOutOfBounds(start+length-1, dynamicArray.length) returns (uint256[] memory) {
        // 创建一个长度是length 的定长数组
        uint256[] memory subArray = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            subArray[i] = dynamicArray[start+i];
        }
        return subArray;
    }

}