//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Lottery {
    address payable[] public players;
    address public manager;

    constructor() {
        manager = msg.sender;
        players.push(payable(manager));
    }

    receive() external payable {
        require(msg.sender != manager, "The manager can not participate");
        require(msg.value == 0.1 ether, "Only accepting 0.1 ether purchases");

        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint) {
        require(msg.sender == manager, "Only the manager can see the balance");

        return address(this).balance;
    }

    function pickWinner() public {
        require(msg.sender == manager, "Only the manager can pick a winner");
        require(players.length >= 3, "Need at least 3 players before picking a winner");

        players[random() % players.length].transfer(getBalance());
        players = new address payable[](0);
    }

    function random() internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
}