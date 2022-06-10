//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './ethereum/interfaces/IRootChainManager.sol';

import './matic/interfaces/IERC20Mintable.sol';

contract CustomBridge {
    address immutable maticBridge;
    address immutable plasmaToken;
    address immutable erc20Predicate;

    constructor(
        address _erc20Predicate,
        address _maticBridge,
        address _plasmaToken
    ) {
        erc20Predicate = _erc20Predicate;
        maticBridge = _maticBridge;
        plasmaToken = _plasmaToken;
    }

    function mintAndTransfer(uint256 amount) external {
        uint256 amountMinted = IERC20Mintable(plasmaToken).mint(address(this), amount);
        IERC20(plasmaToken).approve(erc20Predicate, amountMinted);
        IRootChainManager(maticBridge).depositFor(msg.sender, plasmaToken, abi.encode(amountMinted));
    }
}
