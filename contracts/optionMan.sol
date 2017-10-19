pragma solidity ^0.4.12;

import "github.com/JonnyLatte/MiscSolidity/erc20.sol"; 
import "github.com/JonnyLatte/MiscSolidity/owned.sol";
import "github.com/JonnyLatte/MiscSolidity/appToken.sol";

contract OptionMan is owned, appToken
{
    address public currency;   // Token used to buy
    address public asset;      // Token on offer
    uint256 public price;      // Amount of currency needed to buy a lot (smallest units)
    uint256 public units;      // Amount of asset being sold in a lot (smallest units)
    uint256 public expireTime;  // trading ends at this timestamp
    
    
    modifier onlyBeforeExpire() 
    {
        require(block.timestamp < expireTime);
        _;
    }
    
    modifier onlyAfterExpire() 
    {
        require(block.timestamp > expireTime);
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
        expireTime = block.timestamp + _duration;       

    }
    
    // seller locks asset and is given a token representing the option to buy it
    
    function issue(uint _unitLots)  public 
        onlyOwner
        returns (bool ok)
    {
        require(ERC20(asset).transferFrom(msg.sender, address(this),_unitLots.safeMul(units))); 
        issueTokens(msg.sender,_unitLots);
        return true;
    }

    // at any time owner can release funds by controlling the corrisponding option
    // which will be burned.
    
    function burn(uint _unitLots)  public
        onlyOwner
        returns (bool ok)
    {
        burnTokens(msg.sender,_unitLots);
        require(ERC20(asset).transfer(msg.sender,_unitLots.safeMul(units))); 
        return true;
    }
    
    // after the option expires the owner can withdraw any remaining asset tokens
    
    function withdraw(address _token, uint256 _value) public
        onlyOwner
        onlyAfterExpire
        returns (bool ok)
    {
        require(ERC20(_token).transfer(msg.sender,_value));
        return true;
    }
    
    // currency paid does not need to be locked 
    
    function withdrawCurrency(uint256 _value) public
        onlyOwner
        returns (bool)
    {
        require(ERC20(currency).transfer(msg.sender,_value));
        return true;
    }
    
    // option holder buys asset
    
    function exercise(uint256 _unitLots) public
        onlyBeforeExpire
        returns (bool ok)       
    {
        uint payment = _unitLots.safeMul(price); // amount of currency tokens paid smallest units
        uint purchace = _unitLots.safeMul(units); // amount of asset tokens bought smallest units
        
        burnTokens(msg.sender,_unitLots);
        
        require(ERC20(currency).transferFrom(msg.sender, address(this),payment)); 
        require(ERC20(asset).transfer(msg.sender,purchace)); 
        return true;
    } 
    
}
