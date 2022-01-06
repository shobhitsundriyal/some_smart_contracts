//SPDX-License-Identifier:MIT
//@notice: Tullock auction for highest two bidders
pragma solidity ^0.8.x;

contract Auction {
    address payable owner;
    uint public startBlock;
    uint public endBlock;
    uint ipfsHash;
    uint public winningPrize;

    enum State {Started, Running, Cancelled}
    State public auctionState;

    address sencondHighestBidder;
    uint secondHighestBid;
    address payable public highestBidder;
    uint public highestBid;

    mapping(address=> uint) public bids;
    uint bidIncrement;

    constructor () {
        owner = payable(msg.sender);
        auctionState = State.Cancelled;
        startBlock = 0;
        endBlock = 0; //block time of eth mainet is 15 sec avg so calculate accordingly 1min = 4blocks
        bidIncrement = 1000000000000000000; //1eth wei 0.01 eth
        highestBid = 0;
        secondHighestBid = 0;
        //ipfsHash = "2";
    }

    modifier notOwner(){
        require(msg.sender != owner, "Owner is not allowed here");
        _;
    }

    modifier Owner(){
        require(msg.sender == owner, "Hmm seems you ar not the owner");
        _;
    }

    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }

    function cancelAuction() public Owner {
    auctionState = State.Cancelled;
    }

    function placeBid() public payable notOwner beforeEnd afterStart {
        require(auctionState == State.Running, "Sorry auction is not running right now");
        require(msg.value >= bidIncrement, "Minimum increment is not statisfied");
        require(bids[msg.sender]+msg.value-highestBid >= bidIncrement, "Minimum increment is not statisfied");
        require(msg.value + bids[msg.sender] > highestBid, "Place a larger bid than highest bid");

        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBid, "Current bid is greater");
        sencondHighestBidder = highestBidder; 
        secondHighestBid = highestBid;
        highestBidder = payable(msg.sender);
        highestBid = currentBid;
        bids[msg.sender] = currentBid;
    }

    function bal() public returns(uint){
        return address(this).balance;
    }
    /*You can automatically send the losing bids later but there is "withdrwal patterns" i.e. user gets the  funds back only he/she explicitly requests. don't know this way re-entrace attacks are avoided(plus coding this way is easier too;-)*/
    /*Check this re-entrance attack seems interesting*/
    function requestBalance() public {
        require(auctionState == State.Cancelled, "Auction is still going on request when the auction is over");
        require(msg.sender != highestBidder, "You can get you winning by collect prize method");
        require(msg.sender != sencondHighestBidder, "Read the rules");
        require(bids[msg.sender] > 0 || msg.sender == owner, "You have no balance left");
        
        address payable recepient;
        uint value;
        if (msg.sender == owner){
        recepient = owner;
        value = highestBid + secondHighestBid;
        }
        else{
            recepient = payable(msg.sender);
            value = bids[msg.sender];
            bids[msg.sender] = 0; //reseting the balance who withdraws
        }

        recepient.transfer(value);
    }

    function collectPrize() public {
        require(auctionState == State.Cancelled, "auction is still on");
        require(msg.sender == highestBidder, "Hey, you are not the highest bidder");
        require(highestBid > 0, "You have already claimed the prize");
        payable(msg.sender).transfer(winningPrize);
        highestBid = 0; //otherwise highest bidder can drain the contract balance
    }

    function startAuction(uint _noOfBlocksbeforeEnding) public payable Owner {
        //Start a new auction
        require(auctionState == State.Cancelled, "Auction is already on");
        winningPrize = msg.value;
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + _noOfBlocksbeforeEnding;
    }
}
