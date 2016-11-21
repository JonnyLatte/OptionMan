pragma solidity ^0.4.4;

import "erc20.sol"; 
import "owned.sol";
import "ownedToken.sol";

contract OptionMan is owned
{
    address public currency;   // Token used to buy
    address public asset;      // Token on offer
    uint256 public price;      // Amount of currency needed to buy a lot (smallest units)
    uint256 public units;      // Amount of asset being sold in a lot (smallest units)
    
    uint256 public expireTime;  // trading ends at this timestamp
    
    address public options;

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
		
		// token contract that is controlled by this contract 
		// tokens can be issued or burned at any target address by the owner 
		// or transfered normally by holders:
		
        options = new ownedToken(); 

    }
    
    // seller locks asset and is given a token representing the option to buy it
    
    function issue(uint _value)  
        onlyOwner
        returns (bool ok)
    {
        if(!ERC20(asset).transferFrom(msg.sender, address(this),_value)) throw; 
        if(!ownedToken(options).issue(_value,msg.sender)) throw;
        return true;
    }

    // at any time owner can release funds by controlling the corrisponding option
    // which will be burned.
    
    function burn(uint _value)  
        onlyOwner
        returns (bool ok)
    {
        if(!ownedToken(options).burn(_value,msg.sender)) throw;
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
    
    function exercise(uint256 _value) 
        onlyBeforeExpire 
    {
        uint payment = _value * price / units;
        if(!ownedToken(options).burn(_value,msg.sender)) throw;
        if(!ERC20(currency).transferFrom(msg.sender, address(this),payment)) throw; 
        if(!ERC20(asset).transfer(msg.sender,_value)) throw; 
    } 
    
}

