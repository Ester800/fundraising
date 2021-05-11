//SPDX-License-Identifier: GPL-3.0;

pragma solidity >=0.5.0 <0.9.0;

contract FundRaising{
    mapping(address => uint) public contributors;
    address public admin;
    
    uint public noOfContibutors;
    uint public minContribution;
    uint public deadline;  // this is a timestamp
    uint public goal;
    uint public amountRaised = 0;
    
    // create a struct to handle spending requests, which will be voted upon by contributing members
    struct Request{  
        string description;  // a description of the purchase request...why, what, how much?
        address recipient;  // the vendor, or recipient of spent funds  
        uint value;  // the value to be spent
        bool completed; 
        uint noOfVoters;
        mapping(address => bool) voters;  // by default, this is false!
    }
    
    Request[] public requests;
    
    event ContributeEvent(address sender, uint value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address recipient, uint value);
    
    constructor(uint _goal, uint _deadline) public{
        goal = _goal;
        deadline = block.timestamp + _deadline;
        
        admin = msg.sender;
        minContribution = 10;
    }
    
    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }
    
    function contribute() public payable{
        require(block.timestamp < deadline);
        require(msg.value >= minContribution);
        
        if(contributors[msg.sender] == 0){
            noOfContibutors++;
        }
        
        contributors[msg.sender] += msg.value;
        amountRaised += msg.value;
        
        emit ContributeEvent(msg.sender, msg.value);
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function getRefund() public {
        require(block.timestamp > deadline);
        require(amountRaised < goal);
        require(contributors[msg.sender] > 0);
        
        address recipient = msg.sender;
        uint value = contributors[msg.sender];
        
        recipient.transfer(value);
        contributors[msg.sender] = 0;
        
    } 
    
    function createRequest(string _description, address _recipient, uint _value) public onlyAdmin{
        Request memory newRequest = Request({
            description: _description,
            recipient: _recipient,
            value: _value,
            completed: false,
            noOfVoters: 0
            });
            
            requests.push(newRequest);
            emit CreateRequestEvent(_description, _recipient, _value);
    }
    
    function voteRequest(uint index) public{
        Request storage thisRequest = requests[index];
        require(contributors[msg.sender] > 0);  // allows only contributors to vote
        require(thisRequest.voters[msg.sender] == false); // allows only 1 vote per contributor
        
        thisRequest.voters[msg.sender] = true;  // once a vote is submitted, we change their value to true
        thisRequest.noOfVoters++;  // increment their voting record, it is no longer 0!
    }
    
    function makePayment(uint index) public onlyAdmin{
        Request storage thisRequest = requests[index];
        require(thisRequest.completed == false);  // ensures the transaction isn't completed twice
        require(thisRequest.noOfVoters > noOfContibutors / 2);  // verifies that 50% of contributors have voted
        
        thisRequest.recipient.transfer(thisRequest.value); // transfers funds to recipient/vendor
        thisRequest.completed = true;
        
        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }
}