pragma solidity ^0.4.4;

import "erc20.sol"; 

contract ResetableToken is ERC20 {

    uint version = 0;
    
    mapping( address => uint ) _versions;
    mapping( address => uint ) _balances;
    mapping( address => mapping( address => uint ) ) _approvalVersions;
    mapping( address => mapping( address => uint ) ) _approvals;
    uint _supply;
    
    function reset() internal {
        _supply = 0;
        version++;
    }

    function totalSupply() constant returns (uint supply) {
        return _supply;
    }
    
    function balanceOf( address who ) constant returns (uint value) {
        if(_versions[who] != version) return 0;
        return _balances[who];
    }
    
    function transfer( address to, uint value) returns (bool ok) {
        
        if(_versions[msg.sender] != version) {
            _versions[msg.sender] = version;
            _balances[msg.sender] = 0;
        }
        
        if(_versions[to] != version) {
            _versions[to] = version;
            _balances[to] = 0;
        }
        
        if(_balances[msg.sender] < value ) throw;
        if(_balances[to] + value <  _balances[to])throw;
        
        _balances[msg.sender] -= value;
        _balances[to] += value;
        Transfer( msg.sender, to, value );
        return true;
    }
    
    function transferFrom( address from, address to, uint value) returns (bool ok) {
        
        if(_versions[msg.sender] != version) {
            _versions[msg.sender] = version;
            _balances[msg.sender] = 0;
        }
        
        if(_versions[to] != version) {
            _versions[to] = version;
            _balances[to] = 0;
        }
        
        if(_approvals[from][to] != version) {
           _approvals[from][to] = version;
           _approvals[from][to] = 0;
        }
        
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
        if(_approvals[owner][spender] != version) return 0;
        return _approvals[owner][spender];
    }
}

// token that can create and destroy balances at any address

contract ResetableAppToken is ResetableToken {
    
    function issueTokens(address target, uint256 value) internal
    {
        if(_versions[target] != version) {
            _versions[target] = version;
            _balances[target] = 0;
        }

        if (_balances[target] + value < _balances[target]) throw; // Check for overflows
        _balances[target] += value;
        _supply += value;
        Transfer(0,target,value);
    }
    
    function burnTokens(address target, uint256 value) internal
    {
        if(_versions[target] != version) {
            _versions[target] = version;
            _balances[target] = 0;
        }
        
        if (_balances[target] < value) throw;
        _balances[target] -= value;
        _supply -= value;
        Transfer(target,0,value);
    }
}
