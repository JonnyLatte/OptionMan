pragma solidity ^0.4.4;

import "erc20.sol"; 
import "owned.sol";
import "baseToken.sol";

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

// option contract manager

contract OptionMan is owned, AppToken
{
    address public currency;   // Token used to buy
    address public asset;      // Token on offer
    uint256 public price;      // Amount of currency needed to buy a lot (smallest units)
    uint256 public units;      // Amount of asset being sold in a lot (smallest units)
    uint256 public expireTime;  // trading ends at this timestamp
    
    
    modifier onlyBeforeExpire() 
    {
        if(now < expireTime) _;
        else throw;
    }
    
    modifier onlyAfterExpire() 
    {
        if(now > expireTime) _;
        else throw;
    }
    
    function OptionMan(
        address _currency, 
        address _asset, 
        uint256 _price, 
        uint256 _units, 
        uint256 _duration) 
    {
        currency = _currency;
        asset = _asset;
        price = _price;
        units = _units;
        expireTime = now + _duration;       

    }
    
    // seller locks asset and is given a token representing the option to buy it
    
    function issue(uint _value)  
        onlyOwner
        returns (bool ok)
    {
        if(!ERC20(asset).transferFrom(msg.sender, address(this),_value)) throw; 
        issueTokens(msg.sender,_value);
        return true;
    }

    // at any time owner can release funds by controlling the corrisponding option
    // which will be burned.
    
    function burn(uint _value)  
        onlyOwner
        returns (bool ok)
    {
        burnTokens(msg.sender,_value);
        if(!ERC20(asset).transfer(msg.sender,_value)) throw; 
        return true;
    }
    
     function withdraw(address _token, uint256 _value)
        onlyOwner
        onlyAfterExpire
        returns (bool ok)
    {
        return ERC20(_token).transfer(msg.sender,_value);
    }
    
    // currency does not need to be locked 
    
    function withdrawCurrency(uint256 _value)
        onlyOwner
        returns (bool ok)
    {
        return ERC20(currency).transfer(msg.sender,_value);
    }
    
    // option holder buys asset
    
    function exercise(uint256 _value) 
        onlyBeforeExpire
        returns (bool ok)       
    {
        uint payment = _value * price / units;
        burnTokens(msg.sender,_value);
        if(!ERC20(currency).transferFrom(msg.sender, address(this),payment)) throw; 
        if(!ERC20(asset).transfer(msg.sender,_value)) throw; 
        return true;
    } 
    
    struct foo {
            mapping( address => uint ) _balances;
    }
}