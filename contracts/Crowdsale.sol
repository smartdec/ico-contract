pragma solidity 0.4.19;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract PassTokenSale is Pausable {
  using SafeMath for uint256;

  PassCoin public pass;
  PassContributorWhitelist public whitelist;
  mapping(address => uint256) public participated;

  address public ethFundDepositAddress;
  address public passDepositAddress;

  uint256 public constant tokenCreationCap = 375000000 * 10**18;
  uint256 public totalTokenSold = 0;

  uint256 public constant privateRate = 14200;
  uint256 public constant preRate = 12200;
  uint256 public constant sale1Rate = 11700;
  uint256 public constant sale2Rate = 11200;
  uint256 public constant baseRate = 10100;

  uint256 public fundingStartTime;
  uint256 public fundingPreEndTime;
  uint256 public fundingSale1EndTime;
  uint256 public fundingSale2EndTime;
  uint256 public fundingEndTime;

  uint256 public constant minContribution = 0.1 ether;
  uint256 public constant minPreContribution = 0.1 ether;
  uint256 public constant minPrivateContribution = 15 ether;
  uint256 public constant privateCap = 9000 ether;
  uint256 public constant preCap = 9000 ether;
  uint256 public constant sale1Cap = 6000 ether;
  uint256 public constant sale2Cap = 6000 ether;

  bool public isFinalized;

  event MintPass(address from, address to, uint256 val);
  event RefundPass(address to, uint256 val);

  function PassTokenSale(
    PassCoin _passCoinAddress,
    PassContributorWhitelist _passContributorWhitelistAddress,
    address _ethFundDepositAddress,
    address _passDepositAddress,
    uint256 _fundingStartTime,
    uint256 _fundingPreEndTime,
    uint256 _fundingSale1EndTime,
    uint256 _fundingSale2EndTime,
    uint256 _fundingEndTime
  ) 
    public
  {
    pass = PassCoin(_passCoinAddress);
    whitelist = PassContributorWhitelist(_passContributorWhitelistAddress);
    ethFundDepositAddress = _ethFundDepositAddress;
    passDepositAddress = _passDepositAddress;

    fundingStartTime = _fundingStartTime;
    fundingPreEndTime = _fundingPreEndTime;
    fundingSale1EndTime = _fundingSale1EndTime;
    fundingSale2EndTime = _fundingSale2EndTime;
    fundingEndTime = _fundingEndTime;

    isFinalized = false;
  }

  function buy(address to, uint256 val) internal returns (bool success) {
    MintPass(passDepositAddress, to, val);
    return pass.mint(to, val);
  }

  function() public payable {
    createTokens(msg.sender, msg.value);
  }

  function createTokens(address _beneficiary, uint256 _value) internal whenNotPaused {
    uint256 rate = baseRate;
    require(_beneficiary != 0x0);
    require(now >= fundingStartTime);
    uint256 hardCap = getHardCap();

    if (_value >= minPrivateContribution ){
      require(now <= fundingEndTime);
      rate = privateRate;
      hardCap = privateCap.mul(privateRate);
    }else if (now <= fundingSale2EndTime){
      if (now <= fundingPreEndTime){
        require(_value >= minPreContribution);
      }else{
        require(_value >= minContribution);
      }
      rate = getRate();
    }else{
      require(now <= fundingEndTime);
    }
    require(!isFinalized);

    uint256 tokensToAllocate = _value.mul(rate);

    uint256 cap = whitelist.getCap(_beneficiary);
    require(cap > 0);

    uint256 tokensToRefund = 0;
    uint256 etherToRefund = 0;

    uint256 checkedTokenSold = totalTokenSold.add(tokensToAllocate);

    // if reaches hard cap
    if (hardCap < checkedTokenSold) {
      tokensToRefund   = tokensToAllocate.sub(hardCap.sub(totalTokenSold));
      etherToRefund = tokensToRefund.div(rate);
      totalTokenSold = hardCap;
    } else {
      totalTokenSold = checkedTokenSold;
    }

    // save to participated data
    participated[_beneficiary] = participated[_beneficiary].add(tokensToAllocate);

    // allocate tokens
    require(buy(_beneficiary, tokensToAllocate));
    if (etherToRefund > 0) {
      // refund in case user buy over hard cap
      RefundPass(msg.sender, etherToRefund);
      msg.sender.transfer(etherToRefund);
    }
    ethFundDepositAddress.transfer(this.balance);
    return;
  }

  function getRate() internal constant returns (uint256) {
    uint256 currentRate = baseRate;

    if (now <= fundingPreEndTime) {
      currentRate = preRate;
    } else if (now <= fundingSale1EndTime) {
      currentRate = sale1Rate;
    } else if (now <= fundingSale2EndTime) {
      currentRate = sale2Rate;
    }

    return currentRate;
  }

  function getHardCap() internal constant returns (uint256) {
    uint256 hardCap = 0;

    if (now <= fundingPreEndTime) {
      hardCap = preCap.mul(preRate);
    } else if (now <= fundingSale1EndTime) {
      hardCap = sale1Cap.mul(sale1Rate);
    } else if (now <= fundingSale2EndTime) {
      hardCap = sale2Cap.mul(sale2Rate);
    } else {
      hardCap = tokenCreationCap.sub(totalTokenSold);
    }

    return hardCap;
  }

  /// @dev Ends the funding period and sends the ETH home
  function finalize() external onlyOwner {
    require(!isFinalized);
    // move to operational
    isFinalized = true;
    ethFundDepositAddress.transfer(this.balance);
  }
}
