// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Cryptos is IERC20 {
  string public name = "Cryptos";
  string public symbol = "CRPT";
  uint public decimals = 0;
  uint public override totalSupply;

  address public founder;
  mapping(address => uint) public balances;

  mapping(address => mapping(address => uint)) allowed;

  modifier higherThanZero(uint tokens) {
    require(tokens > 0, "Can not use 0 or less tokens");
    _;
  }

  constructor() {
    totalSupply = 1000000;
    founder = msg.sender;
    balances[founder] = totalSupply;
  }

  function balanceOf(address tokenOwner) public view override returns (uint balance) {
    return balances[tokenOwner];
  }

  function transfer(address to, uint tokens) higherThanZero(tokens) public override returns (bool success) {
    require(balances[msg.sender] >= tokens, "Not enough funds to transfer");

    balances[to] += tokens;
    balances[msg.sender] -= tokens;
    
    emit Transfer(msg.sender, to, tokens);

    return true;
  }

  function allowance(address tokenOwner, address spender) public view override returns(uint) {
    return allowed[tokenOwner][spender];
  }

  function approve(address spender, uint tokens) higherThanZero(tokens) public override returns (bool success) {
    require(balances[msg.sender] >= tokens, "Not enough funds to transfer");

    allowed[msg.sender][spender] = tokens;

    emit Approval(msg.sender, spender, tokens);

    return true;
  }

  function transferFrom(address from, address to, uint tokens) higherThanZero(tokens) public override returns (bool success) {
    require(allowed[from][msg.sender] >= tokens, "Not enough approved funds to transfer");
    require(balances[from] >= tokens, "Not enough funds to transfer");

    balances[from] -= tokens;
    allowed[from][msg.sender] -= tokens;
    balances[to] += tokens;

    emit Transfer(from, to, tokens);

    return true;
  }
}
