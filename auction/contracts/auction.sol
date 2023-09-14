//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract AuctionCreator {
    address public owner;
    Auction[] public auctions;

    constructor() {
        owner = msg.sender;
    }

    function createAuction() public returns(address){
        Auction auction = new Auction(msg.sender);
        auctions.push(auction);

        return address(auction);
    }
}

contract Auction {
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    enum State {Started, Running, Ended, Canceled}
    State public auctionState;

    uint public highestBindingBid;
    address payable public highestBidder;

    mapping(address => uint) public bids;

    uint bidIncrement;

    constructor(address eoa) {
        owner = payable(eoa);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 40320;
        ipfsHash = "";
        bidIncrement = 1000;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this function");
        _;
    }

    modifier notOwner() {
        require(msg.sender != owner, "This cannot be done by the owner of the contract");
        _;
    }

    modifier afterStart() {
        require(block.number >= startBlock, "The auction has not started");
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock, "The auction has ended");
        _;
    }

    function min(uint a, uint b) pure internal returns(uint) {
        if (a <= b) {
            return a;
        }

        return b;
    }

    function placeBid() public payable notOwner afterStart beforeEnd {
        require(auctionState == State.Running, "Cannot place a bid if the auction is not running");

        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid, "Cannot place a bid under the current highest bid");

        bids[msg.sender] = currentBid;
        if(currentBid <= bids[highestBidder]) {
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else {
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }
    
    function cancelAuction() public onlyOwner {
        auctionState = State.Canceled;
    }

    function finalizeAuction() public {
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0);

        address payable recipient;
        uint value;

        if (auctionState == State.Canceled) {
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else {
            if (msg.sender == owner) {
                recipient = owner;
                value = highestBindingBid;
            } else {
                if (msg.sender == highestBidder) {
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                } else {
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }

        bids[recipient] = 0;
        recipient.transfer(value);
    }
}