// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EnumBasics {
    // 定义枚举：状态机（如订单状态、游戏角色状态等）
    enum OrderStatus {
        Pending,    // 默认从0开始，不能多余256个成员（底层类型是uint8）
        Shipped,
        Delivered,
        Cancelled
    }

    // 定义枚举：权限级别
    enum Role {
        Admin,  // 0
        Moderator,  // 1
        User    // 2
    }

    // 状态变量存储枚举
    OrderStatus public currentOrderStatus;
    Role public userRole;

    constructor() {
        // 初始化枚举
        currentOrderStatus = OrderStatus.Pending;
        userRole = Role.User;
    }

    // 更新订单状态（展示枚举的比较和赋值
    function updateOrderStatus(OrderStatus _newStatus) external {
        require(
            uint256(_newStatus) >= uint256(OrderStatus.Pending) &&
            uint256(_newStatus) <= uint256(OrderStatus.Cancelled),
            "Invalid status"
        );
        currentOrderStatus = _newStatus;
    }
    // 检查用户权限（展示枚举在控制流中的用法）
    function checkPermission() external view returns (bool) {
        if (userRole == Role.Admin) {
            return true;
        } else if (userRole == Role.Moderator) {
            return block.timestamp % 2 == 0;    // 模拟复杂逻辑
        } else {
            return false;
        }
    }
}