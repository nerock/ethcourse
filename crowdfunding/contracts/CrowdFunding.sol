// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract CrowdFunding {
  mapping(address => uint) public contributors;
  address public admin;
  uint public nContributors;
  uint public minimumContribution;
  uint public deadline;
  uint public goal;
  struct Request{
    string description;
    address payable recipient;
    uint value;
    bool completed;
    uint nVoters;
    mapping(address => bool) voters;
  }
  mapping(uint => Request) public requests;
  uint public nRequests;

  constructor(uint _goal, uint _deadline) {
    goal = _goal;
    deadline = block.timestamp + _deadline;
    minimumContribution = 100 wei;
    admin = msg.sender;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, "This action can only be performed by the admin");
    _;
  }

  modifier contributed() {
    require(contributors[msg.sender] > 0, "You have no registered contributions");
    _;
  }

  event ContributeEvent(address _sender, uint _value);
  event CreateRequestEvent(string _description, address _recipient, uint _value);
  event MakePaymentEvent(address _recipient, uint _value);

  function contribute() public payable {
    require(block.timestamp < deadline, "Deadline has passed");
    require(msg.value >= minimumContribution, "Minimum contribution not met");

    if (contributors[msg.sender] == 0) {
      nContributors++;
    }

    contributors[msg.sender] += msg.value;
    
    emit ContributeEvent(msg.sender, msg.value);
  }

  receive() payable external {
    contribute();
  }

  function getBalance() public view returns(uint) {
    return address(this).balance;
  }

  function refund() public contributed {
    require(block.timestamp > deadline && address(this).balance < goal, "The deadline has not finished");

    payable(msg.sender).transfer(contributors[msg.sender]);
    contributors[msg.sender] = 0;
  }

  function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
    Request storage newRequest = requests[nRequests];
    nRequests++;

    newRequest.description = _description;
    newRequest.recipient = _recipient;
    newRequest.value = _value;
    newRequest.completed = false;
    newRequest.nVoters = 0;

    emit CreateRequestEvent(_description, _recipient, _value);
  }

  function vote(uint _id) public contributed {
    Request storage request = requests[_id];
    require(request.value != 0, "The request with this id does not exist");
    require(request.voters[msg.sender] == false, "You have already voted");
    
    request.voters[msg.sender] = true;
    request.nVoters++;
  }

  function makePayment(uint _id) public onlyAdmin {
    Request storage request = requests[_id];

    require(address(this).balance >= goal, "The goal has not been reached");
    require(request.completed == false, "The request has been completed");
    require(request.nVoters > nContributors / 2, "More than 50% of contributors must have voted for this request");

    request.recipient.transfer(request.value);
    request.completed = true;

    emit MakePaymentEvent(request.recipient, request.value);
  }
}
