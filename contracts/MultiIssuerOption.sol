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

    ownedToken public shares; // token representing seller claims on contract funds
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
        shares = new ownedToken();
        option = new ownedToken();
    }
    
    function issue(uint256 _value)  
        onlyWhileFunding
        returns (bool ok)
    {
        if(!ERC20(asset).transferFrom(msg.sender, address(this),_value)) throw; 
        if(!ownedToken(shares).issue(_value,msg.sender)) throw;
        if(!ownedToken(option).issue(_value,msg.sender)) throw;
        return true;
    }
    
    // calculae asset and currency cost for late issuance 
    
   function lateIssueCost(uint256 _shares) public returns (uint256 assetCost, uint256 currencyCost) {
        uint256 totalCurrency = ERC20(currency).balanceOf(this);
        uint256 totalAssets = ERC20(asset).balanceOf(this);
        uint256 totalShares = ERC20(shares).totalSupply();
        
        if(totalShares == 0) throw;
        
        assetCost = _shares * totalAssets / totalShares;
        currencyCost = _shares * totalCurrency / totalShares;
    }

    // funding contract after the funding period must preserve claim ratos
    // to acheive this seller must add funds at the current ratio
    // options are awareded for the asset added only so adding after exersise has occured
    // has diminishing returns an no options can be generated when asset:currency
    // ratio is at 0:1 because asset funds cannot be added while preserving the ratio
    
    function lateIssue(uint256 _numberOfShares) 
        onlyAfterFunding
        onlyBeforeExpire
        returns (bool ok)
    {
        var (assetPayment, currencyPayment) = lateIssueCost(_numberOfShares);
    
        if(!ERC20(asset).transferFrom(msg.sender, address(this),assetPayment)) throw; 
        if(!ERC20(currency).transferFrom(msg.sender, address(this),currencyPayment)) throw; 

        if(!ownedToken(shares).issue(_numberOfShares,msg.sender)) throw;
        if(!ownedToken(option).issue(assetPayment,msg.sender)) throw;
        
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
    
    // get the value of a share in asset and currency 
    
    function shareValue(uint256 _value) public returns (uint256 assetValue, uint256 currencyValue) {
        assetValue = ERC20(asset).balanceOf(this) * _value / ERC20(asset).totalSupply();
        currencyValue = ERC20(currency).balanceOf(this) * _value / ERC20(currency).totalSupply();
    }
    
    function redeem(uint256 _value) internal returns (bool ok)
    {
        var (assetValue,currencyValue) = shareValue(_value);
        
        if(!ownedToken(shares).burn(_value,msg.sender)) throw;
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
        var (assetValue,) = shareValue(_value);
        if(!ownedToken(option).burn(assetValue,msg.sender)) throw;
        return redeem(_value);
    }
}
