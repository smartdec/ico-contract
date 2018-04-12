pragma solidity 0.4.21;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./PassCoin.sol";
import "./PassContributorWhitelist.sol";


contract PassTokenSale is Pausable {
    using SafeMath for uint256;

    PassCoin public pass;
    PassContributorWhitelist public whitelist;
    mapping(address => uint256) public participated;

    address public ethFundDepositAddress;
    address public passDepositAddress;

    uint256 public constant TOKEN_CREATION_CAP = 375000000 * 10**18;
    uint256 public totalTokenSold = 0;

    uint256 public constant PRIVATE_RATE = 14200;
    uint256 public constant PRE_RATE = 12200;
    uint256 public constant SALE1_RATE = 11700;
    uint256 public constant SALE2_RATE = 11200;
    uint256 public constant BASE_RATE = 10100;

    uint256 public fundingStartTime;
    uint256 public fundingPreEndTime;
    uint256 public fundingSale1EndTime;
    uint256 public fundingSale2EndTime;
    uint256 public fundingEndTime;

    uint256 public constant MIN_CONTRIBUTION = 0.1 ether;
    uint256 public constant MIN_PRE_CONTRIBUTION = 0.1 ether;
    uint256 public constant MIN_PRIVATE_CONTRIBUTION = 15 ether;
    uint256 public constant PRIVATE_CAP = 9000 ether;
    uint256 public constant PRE_CAP = 9000 ether;
    uint256 public constant SALE1_CAP = 6000 ether;
    uint256 public constant SALE2_CAP = 6000 ether;

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

    function() public payable {
        createTokens(msg.sender, msg.value);
    }

    /// @dev Ends the funding period and sends the ETH home
    function finalize() external onlyOwner {
        require(!isFinalized);
        // move to operational
        isFinalized = true;
        ethFundDepositAddress.transfer(address(this).balance);
    }

    function buy(address to, uint256 val) internal returns (bool success) {
        emit MintPass(passDepositAddress, to, val);
        return pass.mint(to, val);
    }

    function createTokens(address _beneficiary, uint256 _value) internal whenNotPaused {
        uint256 rate = BASE_RATE;
        require(_beneficiary != 0x0);
        require(now >= fundingStartTime);
        uint256 hardCap = getHardCap();

        if (_value >= MIN_PRIVATE_CONTRIBUTION) {
            require(now <= fundingEndTime);
            rate = PRIVATE_RATE;
            hardCap = PRIVATE_CAP.mul(PRIVATE_RATE);
        }else if (now <= fundingSale2EndTime) {
            if (now <= fundingPreEndTime) {
                require(_value >= MIN_PRE_CONTRIBUTION);
            } else {
                require(_value >= MIN_CONTRIBUTION);
            }
            rate = getRate();
        } else {
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
            tokensToRefund = tokensToAllocate.sub(hardCap.sub(totalTokenSold));
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
            emit RefundPass(msg.sender, etherToRefund);
            msg.sender.transfer(etherToRefund);
        }
        ethFundDepositAddress.transfer(address(this).balance);
        return;
    }

    function getRate() internal constant returns (uint256) {
        uint256 currentRate = BASE_RATE;

        if (now <= fundingPreEndTime) {
            currentRate = PRE_RATE;
        } else if (now <= fundingSale1EndTime) {
            currentRate = SALE1_RATE;
        } else if (now <= fundingSale2EndTime) {
            currentRate = SALE2_RATE;
        }

        return currentRate;
    }

    function getHardCap() internal constant returns (uint256) {
        uint256 hardCap = 0;

        if (now <= fundingPreEndTime) {
            hardCap = PRE_CAP.mul(PRE_RATE);
        } else if (now <= fundingSale1EndTime) {
            hardCap = SALE1_CAP.mul(SALE1_RATE);
        } else if (now <= fundingSale2EndTime) {
            hardCap = SALE2_CAP.mul(SALE2_RATE);
        } else {
            hardCap = TOKEN_CREATION_CAP.sub(totalTokenSold);
        }

        return hardCap;
    }
}
