pragma solidity ^0.4.4;

import "erc20.sol"; 
import "ownedToken.sol";

contract MultiIssuerOption 
{
    address public currency;   // Token used to buy / exsise
    address public asset;      // Token on offer
    uint256 public price;      // Amount of currency needed to buy a lot (smallest units)
    uint256 public units;      // Amount of asset being sold in a lot (smallest units)
    
    uint256 public expireTime;  // trading ends at this timestamp
    uint256 public fundingTime; // funding ends at this 

    ownedToken public issuer; // token representing seller claims on contract funds
    ownedToken public option; // token giving holder the right to buy asset with currency

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
    
    modifier onlyWhileFunding() 
    {
        if(now < fundingTime) _;
        else throw;
    }
    
    modifier onlyAfterFunding() 
    {
        if(now > fundingTime) _;
        else throw;
    }
    
    function MultiIssuerOption(
        address _currency, 
        address _asset, 
        uint256 _price, 
        uint256 _units, 
        uint256 _expireInterval,
        uint256 _fundingInterval) 
    {
        currency = _currency;
        asset = _asset;
        price = _price;
        units = _units;
        fundingTime = now + _fundingInterval;
        expireTime = now + _fundingInterval + _expireInterval;
        issuer = new ownedToken();
        option = new ownedToken();
    }
    
    function issue(uint256 _value)  
        onlyWhileFunding
        returns (bool ok)
    {
        if(!ERC20(asset).transferFrom(msg.sender, address(this),_value)) throw; 
        if(!ownedToken(issuer).issue(_value,msg.sender)) throw;
        if(!ownedToken(option).issue(_value,msg.sender)) throw;
        return true;
    }
    
    /* 
    
    // after funding period it is possible for the contract to contain currency

    function lateIssue(uint256 _value) 
        onlyAfterFunding
        onlyBeforeExpire
        returns (bool ok)
    {
        throw; 
        
        // seller is depositing _value amount of asset and needs to be awareded
        // enough issuertokens so that they can claim that amount back
        
        // they also need to deposit enough currency to cover any currency 
        // they may redeem in the pprocess
        
        return true;
    }
    
    /* */

    function exercise(uint256 _value) 
        onlyAfterFunding
        onlyBeforeExpire
        returns (bool ok)
    {
        if(_value * price < _value) throw; //overflow check
        
        uint payment = (_value * price) / units;
        
        if(!ownedToken(option).burn(_value,msg.sender)) throw;
        if(!ERC20(currency).transferFrom(msg.sender, address(this),payment)) throw; 
        if(!ERC20(asset).transfer(msg.sender,_value)) throw; 

        return true;
    }
    
    function redeem(uint256 _value) internal returns (bool ok)
    {
        uint256 assetValue = ERC20(asset).balanceOf(this) * _value / ERC20(asset).totalSupply();
        uint256 currencyValue = ERC20(currency).balanceOf(this) * _value / ERC20(currency).totalSupply();

        if(!ownedToken(issuer).burn(_value,msg.sender)) throw;
        if(!ERC20(asset).transfer(msg.sender,assetValue)) throw;
        if(!ERC20(currency).transfer(msg.sender,assetValue)) throw;
        
        return true;
    }
    
    // seller withraws funds after expiry in the ratio available
    
    function withdrawFunds(uint256 _value) 
        onlyAfterExpire
        returns (bool ok) 
    {
        return redeem(_value);
    } 
    
    // seller burns options to withdraw early
    
    function earlyWithdrawFunds(uint256 _value)
        returns (bool ok) 
    {
        if(!ownedToken(option).burn(_value,msg.sender)) throw;
        return redeem(_value);
    }
}
