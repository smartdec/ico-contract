pragma solidity 0.4.21;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";


contract PassContributorWhitelist is Ownable {

    mapping(address => uint256) public whitelist;

    function PassContributorWhitelist() public {}

    event ListAddress(address _user, uint256 cap, uint256 _time);

    function listAddress(address _user, uint256 cap) public onlyOwner {
        whitelist[_user] = cap;
        emit ListAddress(_user, cap, now);
    }

    function listAddresses(address[] _users, uint256[] _caps) public onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            listAddress(_users[i], _caps[i]);
        }
    }

    function getCap(address _user) public view returns(uint) {
        return whitelist[_user];
    }
}
