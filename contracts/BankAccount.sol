// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract BankAccount {
    //MARK: - events
    event Deposit(
        address indexed user,
        uint256 indexed accountId,
        uint256 value,
        uint256 timestamp
    );

    event WithdrawRequested(
        address indexed user,
        uint256 indexed accountId,
        uint256 indexed withdrawId,
        uint256 amount,
        uint256 timestamp
    );

    event Withdraw(uint indexed withdrawId, uint timestamp);

    event AccountCreated(address[] owners, uint indexed id, uint timestamp);

    //MARK: - structs
    struct WithdrawRequest {
        address user;
        uint amount;
        bool approved;
        uint approvals;
        mapping(address => bool) ownersApproved;
    }

    struct Account {
        address[] owners;
        uint balance;
        mapping(uint => WithdrawRequest) withdrawRequests;
    }

    //MARK: - properties
    mapping(uint => Account) accounts;
    mapping(address => uint[]) userAccounts;
    uint nextAccountId;
    uint nextWithdrawId;

    //MARK: - Modifiers
    modifier accountOwner(uint accountId) {
        bool isOwner;
        for (uint i; i < accounts[accountId].owners.length; i++) {
            if (accounts[accountId].owners[i] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "You are not an owner of this account");
        _;
    }

    modifier validOwners(address[] calldata owners) {
        require(owners.length + 1 <= 4, "maximum of 4 owners per account");
        for (uint i; i < owners.length; i++) {
            for (uint j = i + 1; j < owners.length; j++) {
                if (owners[i] == owners[j]) {
                    revert("no duplicate owners allowed");
                }
            }
        }
        _;
    }

    modifier sufficientBalance(uint accountId, uint amount) {
        require(accounts[accountId].balance >= amount, "insufficientBalance");
        _;
    }

    modifier canApprove(uint accountId, uint withdrawId) {
        require(
            !accounts[accountId].withdrawRequests[withdrawId].approved,
            "this request is already approved"
        );
        require(
            !accounts[accountId].withdrawRequests[withdrawId].ownersApproved[
                msg.sender
            ],
            "you have already approved this request"
        );
        require(
            accounts[accountId].withdrawRequests[withdrawId].user != msg.sender,
            "you can't approve this request"
        );
        require(
            accounts[accountId].withdrawRequests[withdrawId].user != address(0),
            "this request doesn't exist"
        );
        _;
    }

    modifier canWithdraw(uint accountId, uint withdrawId) {
        require(
            accounts[accountId].withdrawRequests[withdrawId].user == msg.sender,
            "you didn't send this request"
        );
        require(
            accounts[accountId].withdrawRequests[withdrawId].approved,
            "this request is not approved"
        );
        _;
    }

    //MARK: - Functions
    function deposit(uint accountId) external payable accountOwner(accountId) {
        accounts[accountId].balance += msg.value;
    }

    function createAccount(
        address[] calldata otherOwners
    ) external validOwners(otherOwners) {
        address[] memory owners = new address[](otherOwners.length + 1);
        owners[otherOwners.length] = msg.sender;
        uint id = nextAccountId;
        for (uint i; i < owners.length; i++) {
            if (i < owners.length - 1) {
                owners[i] = otherOwners[i];
            }
            if (userAccounts[owners[i]].length > 2) {
                revert("each user can have a maximum of 3 accounts");
            }
            userAccounts[owners[i]].push(id);
        }
        accounts[id].owners = owners;
        nextAccountId++;
        emit AccountCreated(owners, id, block.timestamp);
    }

    function requestWithdrawal(
        uint accountId,
        uint amount
    ) external accountOwner(accountId) sufficientBalance(accountId, amount) {
        WithdrawRequest storage request = accounts[accountId].withdrawRequests[
            nextWithdrawId
        ];
        request.user = msg.sender;
        request.amount = amount;
        nextWithdrawId++;
        emit WithdrawRequested(
            msg.sender,
            accountId,
            nextWithdrawId,
            amount,
            block.timestamp
        );
    }

    function approveWithdrawal(
        uint accountId,
        uint withdrawId
    ) external canApprove(accountId, withdrawId) {
        WithdrawRequest storage request = accounts[accountId].withdrawRequests[
            withdrawId
        ];
        request.approvals++;
        request.ownersApproved[msg.sender] = true;

        if (request.approvals == accounts[accountId].owners.length - 1) {
            request.approved = true;
        }
    }

    function withdraw(
        uint accountId,
        uint withdrawId
    ) external canWithdraw(accountId, withdrawId) {
        uint amount = accounts[accountId].withdrawRequests[withdrawId].amount;
        require(accounts[accountId].balance >= amount, "insufficient balance");

        accounts[accountId].balance -= amount;
        delete accounts[accountId].withdrawRequests[withdrawId];

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent);

        emit Withdraw(withdrawId, block.timestamp);
    }

    function getBalance(uint accountId) public view returns (uint) {}

    function getOwners(uint accountId) public view returns (address[] memory) {}

    function getApprovals(
        uint accountId,
        uint withdrawId
    ) public view returns (uint) {}

    function getAccounts() public view returns (uint[] memory) {}
}
