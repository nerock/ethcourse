// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Cryptos.sol";

contract CryptosICO is Cryptos {
  address public admin;
  address payable public deposit;

  uint tokenPrice = 0.001 ether;
  uint public hardCap = 300 ether;
  uint public raisedAmount;
  uint public saleStart = block.timestamp;
  uint public saleEnd = block.timestamp + 604800; // ico ends in a week
  uint public tokenTradeStart = saleEnd + 604800; // transferable one week after sale end
  uint public maxInvestment = 5 ether;
  uint public minInvestment = 0.1 ether;

  enum State {beforeStart, running, afterEnd, halted}
  State public icoState;

  constructor(address payable _deposit) {
    deposit = _deposit;
    admin = msg.sender;
    icoState = State.beforeStart;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, "Only the admin can execute this function");
    _;
  }

  modifier trasnferable() {
    require(block.timestamp > tokenTradeStart);
    _;
  }

  function halt() public onlyAdmin {
    icoState = State.halted;
  }

  function resume() public onlyAdmin() {
    icoState = State.running;
  }

  function changeDepositAddress(address payable newDeposit) public onlyAdmin {
    deposit = newDeposit;
  }

  function getCurrentState() public view returns(State) {
    if (icoState == State.halted) {
      return icoState;
    } else if (block.timestamp < saleStart) {
      return State.beforeStart;
    } else if (block.timestamp >= saleEnd) {
      return State.afterEnd;
    }

    return State.running;
  }

  event Invest(address investor, uint value, uint tokens);
  function invest() payable public returns(bool) {
    require(getCurrentState() == State.running, "The ICO is not running");
    require(msg.value >= minInvestment, "The value is below minimum investment");
    require(raisedAmount + msg.value <= hardCap, "The investment exceeds the hard cap of the ico");

    uint tokens = msg.value / tokenPrice;
    raisedAmount += msg.value;

    balances[msg.sender] += tokens;
    balances[founder] -= tokens;
    deposit.transfer(msg.value);

    emit Invest(msg.sender, msg.value, tokens);
    return true;
  }

  receive() payable external {
    invest();
  }

  function transfer(address to, uint tokens) higherThanZero(tokens) public override trasnferable returns (bool success) {
    return super.transfer(to, tokens);
  }

  function transferFrom(address from, address to, uint tokens) higherThanZero(tokens) public override trasnferable returns (bool success) {
    return super.transferFrom(from, to, tokens);
  }
}
