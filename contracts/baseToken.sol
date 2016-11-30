pragma solidity ^0.4.4;

import "erc20.sol"; 

contract baseToken is ERC20 {
    
    mapping( address => uint ) _balances;
    mapping( address => mapping( address => uint ) ) _approvals;
    uint _supply;

    function totalSupply() constant returns (uint supply) {
        return _supply;
    }
    
    function balanceOf( address who ) constant returns (uint value) {
        return _balances[who];
    }
    
    function transfer( address to, uint value) returns (bool ok) {
        if( _balances[msg.sender] < value ) throw;
        if(_balances[to] + value <  _balances[to])throw;
        
        _balances[msg.sender] -= value;
        _balances[to] += value;
        Transfer( msg.sender, to, value );
        return true;
    }
    
    function transferFrom( address from, address to, uint value) returns (bool ok) {
        // if you don't have enough balance, throw
        if( _balances[from] < value ) {
            throw;
        }
        // if you don't have approval, throw
        if( _approvals[from][msg.sender] < value ) throw;
        if(_balances[to] + value < _balances[to]) throw;
        // transfer and return true
        _approvals[from][msg.sender] -= value;
        _balances[from] -= value;
        _balances[to] += value;
        Transfer( from, to, value );
        return true;
    }
    
    function approve(address spender, uint value) returns (bool ok) {
        _approvals[msg.sender][spender] = value;
        Approval( msg.sender, spender, value );
        return true;
    }
    
    function allowance(address owner, address spender) constant returns (uint _allowance) {
        return _approvals[owner][spender];
    }
}

// token that can create and destroy balances at any address

contract AppToken is baseToken {
    
    function issueTokens(address target, uint256 value) internal
    {
        if (_balances[target] + value < _balances[target]) throw; // Check for overflows
        _balances[target] += value;
        _supply += value;
        Transfer(0,target,value);
    }
    
    function burnTokens(address target, uint256 value) internal
    {
        if (_balances[target] < value) throw;
        _balances[target] -= value;
        _supply -= value;
        Transfer(target,0,value);
    }
}
