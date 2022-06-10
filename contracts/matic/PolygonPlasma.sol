//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract PolygonPlasma is ERC20, Ownable {
    address public childChainManagerProxy;

    mapping(address => bool) public whitelistedAddresses;
    bool public allTransfersWhiteListed;

    constructor(
        string memory name,
        string memory symbol,
        address _childChainManagerProxy,
        address _owner
    ) ERC20(name, symbol) Ownable() {
        childChainManagerProxy = _childChainManagerProxy;
        whitelistedAddresses[childChainManagerProxy] = true;
        Ownable.transferOwnership(_owner);
    }

    function updateChildChainManager(address newChildChainManagerProxy) external onlyOwner {
        require(newChildChainManagerProxy != address(0), 'Bad ChildChainManagerProxy address');

        childChainManagerProxy = newChildChainManagerProxy;
        whitelistedAddresses[childChainManagerProxy] = false;
        whitelistedAddresses[newChildChainManagerProxy] = true;
    }

    function deposit(address user, bytes calldata depositData) external {
        require(msg.sender == childChainManagerProxy, "You're not allowed to deposit");

        uint256 amount = abi.decode(depositData, (uint256));

        _mint(user, amount);
    }

    function withdraw(uint256) external pure {
        revert("Can't withdraw plasma to other network");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal view override {
        require(isWhiteListedTransfer(from, to), "Can't transfer plasma to other account");
    }

    function addAddressToWhiteList(address _addr) external onlyOwner {
        whitelistedAddresses[_addr] = true;
    }

    function removeAddressFromWhitelist(address _addr) external onlyOwner {
        whitelistedAddresses[_addr] = false;
    }

    function enableAllTransfers() external onlyOwner {
        allTransfersWhiteListed = true;
    }

    function disableAllTransfers() external onlyOwner {
        allTransfersWhiteListed = false;
    }

    function isWhiteListedTransfer(address from, address to) internal view returns (bool) {
        return allTransfersWhiteListed || whitelistedAddresses[from] || whitelistedAddresses[to];
    }
}
