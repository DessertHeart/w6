// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;


contract Treasury {

    event Deposit(address indexed sender, uint amount, uint balance);

    uint public balance;

    constructor() payable {
        balance = msg.value;
    }

    receive() payable external{
        balance += msg.value;
        emit Deposit(msg.sender, msg.value, balance);
    }

    function withdraw() payable external {
        uint amount = balance;
        balance = 0;
        
        (bool success, ) = payable(tx.origin).call{value: amount}("");
        require(success, "Transfer Error");
    }

}