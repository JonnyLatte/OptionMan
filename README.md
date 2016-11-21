# OptionMan

Ethereum Option contract, one issuer many option holders

Contract owner can issue the right to buy at a fixed price before an expiry time an asset by locking the asset. 
This right is represented as a standard token that can then be sold on exchanges.

Before expiry:
- Issuer can lock asset and receive options
- Issuer can burn options to release asset
- Issuer can withdraw excised funds (currency)
- Option holder can pay currency to buy asset

After expiry:
- Option holder tokens cannot be used to by and so are worthless
- Issuer can withdraw all funds from contract of any type


Issues / thoughts:
- Could incentivise a denial of service attack from the issier to the option holder to prevent exersise when un exersised options are deep in the money
- Liquidity could be improved with multiple issuers This contract does not attempt to solve that problem
- Some option sellers might prefer an option that can only be exersised at or close to expiry this contract does not attempt to solve that problem 
- This current version has no events in the option code
- This code is untested and likely contains errors. It is for demonstration purposes only. All included code requires audit or replacement with audited code. 