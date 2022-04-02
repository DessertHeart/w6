// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;


contract Governor {

    event SubmitTransaction(address indexed owner, uint indexed txIndex);
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    struct Transaction {
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    address public target;
    Transaction[] public transactions;
    address[] public owners;
    mapping(address => bool) public isOwner;
    // tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;
    uint public numConfirmationsRequired;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }
    
    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address _target, uint _numConfirmationsRequired, address[] memory _owners) {
        target = _target;
        numConfirmationsRequired = _numConfirmationsRequired;

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
    }

    function submitTransaction(
        bytes memory _data
    ) public {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex);
    }

    function confirmTransaction(uint _txIndex)
        public
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex)
        public
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = target.call(abi.encodeWithSignature("withdraw()"));
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

}