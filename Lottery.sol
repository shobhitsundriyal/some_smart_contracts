//SPDX-License-Identifier:MIT

pragma solidity ^0.8.x;

contract Lottery {
    uint public minimumBet; 
    address payable[] public players;
    struct Organizer_detail {
        address organizer_addr;
        string organizer_name;
    }
    Organizer_detail public organizer;
    //msg.sender ==> who calls the fuction
    constructor (string memory _orgName, uint _minBetAmount){
        //runs only at time of contract creation 
        organizer = Organizer_detail(msg.sender,_orgName);
        minimumBet = _minBetAmount; //in wei
    }

    receive() external payable {
        //contract can have only 1 this type of fuction with external and payable required and name recive to pay directly to contract
        //recives eth from players and push players address to dynamic array
        require(uint(msg.value) >= minimumBet, "Minimum amount not met"); //if this condition fails blockchain will revet to previous state but because this line ran it will consume gas, if anything was above this that would consume gas too.
        players.push(payable(msg.sender));
    }

    function totalPrizePool () public view returns(uint){
        //Contracts balance this==>contract's address
        return address(this).balance; //wei
    } 

    function random() private returns(uint){
        //its simple random no generator, but don't use it for real game that time better to use chainlink
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinner() public {
        // only organizer can pick the winner
        require(msg.sender == organizer.organizer_addr, "Hmmm, it seems you are not the Organizer");
        require(players.length >= 5, "Its too early more participants required");

        uint rand_no = random();
        uint idx = rand_no%players.length;
        address payable winner = players[idx];

        //return winner;
        //organizer get 5% and transfer rest funds to winner
        payable(organizer.organizer_addr).transfer(totalPrizePool()/20); //5% == 5/100 == 1/20
        winner.transfer(totalPrizePool());

        players = new address payable[](0); //emptying the array hence resetting the lottery

    }
}
