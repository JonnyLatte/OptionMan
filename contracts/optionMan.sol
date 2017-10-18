pragma solidity ^0.4.12;

import "github.com/JonnyLatte/MiscSolidity/erc20.sol"; 
import "github.com/JonnyLatte/MiscSolidity/owned.sol";
import "github.com/JonnyLatte/MiscSolidity/appToken.sol";

// option contract manager

contract OptionMan is owned, appToken
{
    address public currency;   // Token used to buy
    address public asset;      // Token on offer
    uint256 public price;      // Amount of currency needed to buy a lot (smallest units)
    uint256 public units;      // Amount of asset being sold in a lot (smallest units)
    uint256 public expireTime;  // trading ends at this timestamp
    
    
    modifier onlyBeforeExpire() 
    {
        require(now < expireTime);
        _;
    }
    
    modifier onlyAfterExpire() 
    {
        require(now > expireTime);
        _;
    }
    
    function OptionMan(
        address _currency, 
        address _asset, 
        uint256 _price, 
        uint256 _units, 
        uint256 _duration) public
    {
        currency = _currency;
        asset = _asset;
        price = _price;
        units = _units;
        expireTime = now + _duration;       

    }
    
    // seller locks asset and is given a token representing the option to buy it
    
    function issue(uint _value)  public 
        onlyOwner
        returns (bool ok)
    {
        require(ERC20(asset).transferFrom(msg.sender, address(this),_value)); 
        issueTokens(msg.sender,_value);
        return true;
    }

    // at any time owner can release funds by controlling the corrisponding option
    // which will be burned.
    
    function burn(uint _value)  public
        onlyOwner
        returns (bool ok)
    {
        burnTokens(msg.sender,_value);
        require(ERC20(asset).transfer(msg.sender,_value)); 
        return true;
    }
    
     function withdraw(address _token, uint256 _value) public
        onlyOwner
        onlyAfterExpire
        returns (bool ok)
    {
        require(ERC20(_token).transfer(msg.sender,_value));
        return true;
    }
    
    // currency does not need to be locked 
    
    function withdrawCurrency(uint256 _value) public
        onlyOwner
        returns (bool)
    {
        require(ERC20(currency).transfer(msg.sender,_value));
        return true;
    }
    
    // option holder buys asset
    
    function exercise(uint256 _value) public
        onlyBeforeExpire
        returns (bool ok)       
    {
        uint payment = _value * price / units;
        burnTokens(msg.sender,_value);
        require(ERC20(currency).transferFrom(msg.sender, address(this),payment)); 
        require(ERC20(asset).transfer(msg.sender,_value)); 
        return true;
    } 
    
}
