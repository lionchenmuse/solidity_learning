// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract RoleManagement {
    enum Role {
        None,
        Admin,
        Moderator
    }

    mapping(address => Role) public userRoles;
    address public admin;

    constructor() {
        admin = msg.sender;
        userRoles[admin] = Role.Admin;
    }

    modifier onlyAdmin() { 
        require(uint256(userRoles[msg.sender]) == uint256(Role.Admin), "Only admin");
        _;
    }

    modifier checkRole(Role _role) {
        require(
            uint256(_role) >= uint256(Role.None) && uint256(_role) <= uint256(Role.Moderator), 
            "Invalid role"
        );
        _;
    }

    function grantRole(address _user, Role _role) external onlyAdmin checkRole(_role) {
        
        userRoles[_user] = _role;
    }
}