pragma solidity 0.4.21;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/token/ERC20/PausableToken.sol";


contract PassCoin is PausableToken {
  
    string public constant name = "PASS Token";
    string public constant symbol = "PASS";
    uint8 public constant decimals = 18;

    address public tokenSaleAddress;
    address public passDepositAddress; // multisig wallet

    uint256 public constant PASS_DEPOSIT = 1000000000 * uint(10)**decimals;

    function PassCoin(address _passDepositAddress) public {
        passDepositAddress = _passDepositAddress;
        balances[passDepositAddress] = PASS_DEPOSIT;
        emit Transfer(0x0, passDepositAddress, PASS_DEPOSIT);
        totalSupply_ = PASS_DEPOSIT;
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
        emit Transfer(passDepositAddress, _recipient, _value);
        return true;
    }
}
