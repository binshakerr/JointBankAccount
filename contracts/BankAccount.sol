// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract BankAccount {

    event Deposit(
        address indexed user,
        uint256 indexed accountId,
        uint256 value,
        uint256 timestamp
    )

    event RequestWithdraw(
        address indexed user,
        uint256 indexed accountId,
        uint256 indexed withdrawId,
        uint256 amount,
        uint256 timestamp
    )

    event Withdraw(
        uint indexed withdrawId,
        uint timestamp
    )

    event AccountCreated(
        address[] owners,
        uint indexed id,
        uint timestamp
    )
}
