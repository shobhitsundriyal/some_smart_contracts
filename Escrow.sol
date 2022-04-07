// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    address public party1;
    address public party2;
    address payer;
    address reciver;
    address disputeSetller = address(0);
    address withdrawsInCaseOfDispute;

    bool didP1AddedSetller;
    bool didP2AddedSetller;
    bool didOtherPartyAggred;

    enum State {ongoing, submitted, finished, disputed}
    State public currentState;

    string public workLink;

    constructor(address _otherParty){
        party1 = msg.sender;
        party2 = _otherParty;
        currentState = State.ongoing;
    }

    modifier involvedParties(){
        require(msg.sender == party1 || msg.sender == party2, 'You are not involved');
        _;
    }

    function addDisputeSteller(address _disputeSetller) public involvedParties {
        msg.sender == party1 ? didP1AddedSetller=true : didP2AddedSetller=true;
        disputeSetller = _disputeSetller;
    }

    function agreedToDisputeSetller() public involvedParties {
        if(msg.sender == party1){
            require(didP2AddedSetller, 'No dispute Settler is present/Let other party to aggree');
        }else if(msg.sender == party2){
            require(didP1AddedSetller, 'No dispute Settler is present/Let other party to aggree');
        }
        
        didOtherPartyAggred = true;
    }

    function lockTheEth() public payable involvedParties{
        require(didOtherPartyAggred, 'First aggree on the dispute settler');
        payer = msg.sender;
        reciver = payer==party1 ? party2 : party1;
    }

    function submitWork(string memory _link) public {
        require(msg.sender == reciver, 'You are not working on this');
        workLink = _link;
        currentState = State.submitted;
    }

    function recivePayment() public {
        require(msg.sender==reciver, 'You are not the reciver');
        require(currentState == State.finished, 'Cant withdraw right now');
        payable(reciver).transfer(address(this).balance);
        //maybe reset everything
    }

    function markAsFinished() public {
        require(msg.sender == payer);
        currentState = State.finished;
    }

    function raiseDispute() public involvedParties {
        currentState = State.disputed;
    }

    function resolveDispute(address _caseWinner) public {
        require(disputeSetller ==  msg.sender, 'You are not dispute setller');
        require(_caseWinner==party2 || _caseWinner==party1, 'This address dont bolong to any parties');
        withdrawsInCaseOfDispute = _caseWinner;
    }

    function withdralDisputed() public {
        require(currentState == State.disputed, 'There isnt any dispute');
        require(withdrawsInCaseOfDispute != address(0), 'The dispute is not setteled by Setller');
        require(withdrawsInCaseOfDispute == msg.sender, 'you did not won the case');
        payable(msg.sender).transfer(address(this).balance);
        //reset everythin
    }
}
