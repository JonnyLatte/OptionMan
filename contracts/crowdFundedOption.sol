pragma solidity ^0.4.4;

import "optionMan.sol"; 

contract CrowdFundedOption is AppToken {
    
    OptionMan public option;
    
    uint256 public fundingTime; // funding ends at this 
    
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
    
    function CrowdFundedOption(
        address _currency, 
        address _asset, 
        uint256 _price, 
        uint256 _units, 
        uint256 _optionDuration,
        uint256 _fundingDuration) 
    {
        fundingTime = now + _fundingDuration;
        
        option  = new OptionMan(
            _currency,
            _asset,
            _price,
            _units,
            _fundingDuration+_optionDuration);       

    }
    
    function buyShare(uint256 _value) 
        onlyWhileFunding
        returns (bool ok)
    {
        // collect funds
        if(!ERC20(option.asset()).transferFrom(msg.sender, address(this),_value)) throw;
        
        // issue options
        if(!ERC20(option.asset()).approve(option,_value)) throw;
        if(!option.issue(_value)) throw;
        
        // tranfer options to sender
        option.transfer(msg.sender,_value);
        
        // grant sender shares
        issueTokens(msg.sender,_value);
        return true;
    }
    
    // get the value of a share in asset and currency 
    
    function shareValue(uint256 _value) public returns (uint256 assetValue, uint256 currencyValue) {
        
        var asset = ERC20(option.asset());
        var currency = ERC20(option.currency());
        
        assetValue = asset.balanceOf(option) * _value / asset.totalSupply();
        currencyValue = currency.balanceOf(option) * _value / currency.totalSupply();
    }    
    
    function earlyWithdraw(uint256 _value) {
        // burn sender shares
        burnTokens(msg.sender,_value);
        
        var asset = ERC20(option.asset());
        var currency = ERC20(option.currency());
        var assetValue = asset.balanceOf(option) * _value / asset.totalSupply();
        var currencyValue = currency.balanceOf(option) * _value / currency.totalSupply();
        
        // collect user option
        if(!ERC20(option).transferFrom(msg.sender, address(this),assetValue)) throw;
        
        // release asset funds
        option.burn(assetValue);
        
        // transfer asset funds to sender
        if(!asset.transfer(msg.sender,assetValue)) throw;
        
        // claim currency funds
        option.withdrawCurrency(currencyValue);
        
        // transfer currency funds to sender
        if(!currency.transfer(msg.sender,currencyValue)) throw;
        
    }
    
    function withdraw(uint256 _value) {
        // burn sender shares
        burnTokens(msg.sender,_value);
        
        var asset = ERC20(option.asset());
        var currency = ERC20(option.currency());
        var assetValue = asset.balanceOf(option) * _value / asset.totalSupply();
        var currencyValue = currency.balanceOf(option) * _value / currency.totalSupply();
        
        // release asset funds
        option.withdraw(asset,assetValue);
        
        // transfer asset funds to sender
        if(!asset.transfer(msg.sender,assetValue)) throw;
        
        // claim currency funds
        option.withdrawCurrency(currencyValue);
        
        // transfer currency funds to sender
        if(!currency.transfer(msg.sender,currencyValue)) throw;
    }
    
}