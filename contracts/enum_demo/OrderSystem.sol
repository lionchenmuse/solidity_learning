// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract OrderSystem {
    enum Status {
        Pending,
        Paid,
        Shipped,
        Refunded
    }

    struct Order {
        address buyer;
        uint256 amount;
        Status status;
        uint256 createdAt;
    }

    Order[] public orders;

    function createOrder() external payable {
        orders.push(Order({
            buyer: msg.sender,
            amount: msg.value,
            status: Status.Pending,
            createdAt: block.timestamp
        }));
    }

    modifier checkStatus(Status _newStatus) {
        require(
            uint256(_newStatus) >= uint256(Status.Pending) &&
            uint256(_newStatus) <= uint256(Status.Refunded),
            "Invalid status");
        _;
    }

    function updateStatus(uint256 _orderId, Status _newStatus) external checkStatus(_newStatus) {
        require(_orderId < orders.length, "Invalid order");
        orders[_orderId].status = _newStatus;
    }

    function orderDetails(uint256 _orderId) external view returns (Order memory) {
        require(_orderId < orders.length, "Invalid order");
        return orders[_orderId];
    }
}