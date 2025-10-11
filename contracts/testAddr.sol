// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract testAddr {
    // payable：表示该合约在创建时可以接收以太币
    constructor() payable {

    }

    function testTrnasfer(address payable x) public {
        // this 是当前合约，由于合约也是一个账户，所以它也有地址
        // 这里将当前合约强转成一个address
        address myAddress = address(this);

        if (myAddress.balance >= 10 ether) {
            // 注意：这里是从myAddress也就是 this转1 ether 给 x！！！
            x.transfer(1 ether);
        }

    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}