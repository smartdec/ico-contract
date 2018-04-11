pragma solidity 0.4.19;


import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/token/ERC20/PausableToken.sol";



contract PassCoin is PausableToken {
  string public constant name = "Pass Token";
  string public constant symbol = "PASS";
  uint8 public constant decimals = 18;
  address public tokenSaleAddress;
  address public passDepositAddress; // multisig wallet

  uint256 public constant passDeposit = 1000000000 * 10**decimals;

  function PassCoin(address _passDepositAddress) public {
    passDepositAddress = _passDepositAddress;
    balances[passDepositAddress] = passDeposit;
    Transfer(0x0, passDepositAddress, passDeposit);
    totalSupply_ = passDeposit;
  }

  // Setup Token Sale Smart Contract
  function setTokenSaleAddress(address _tokenSaleAddress) public onlyOwner {
    if (_tokenSaleAddress != address(0)) {
      tokenSaleAddress = _tokenSaleAddress;
    }
  }

  function mint(address _recipient, uint256 _value) public whenNotPaused returns (bool success) {
      require(_value > 0);
      // This function is only called by Token Sale Smart Contract
      require(msg.sender == tokenSaleAddress);
      balances[passDepositAddress] = balances[passDepositAddress].sub(_value);
      balances[_recipient] = balances[_recipient].add(_value);
      Transfer(passDepositAddress, _recipient, _value);
      return true;
  }
}
