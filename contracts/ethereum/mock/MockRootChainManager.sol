//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import '../interfaces/IRootChainManager.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// this will only transfer to user on same chain, however it matches the interface of matic bridge. When matched with matic bridge it will transfer to matic
contract MockRootChainManager is IRootChainManager {
    event DepositFor(address indexed user, address indexed rootToken, uint256 amount);

    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external override {
        uint256 amount = abi.decode(depositData, (uint256));
        IERC20(rootToken).transferFrom(msg.sender, user, amount);
        emit DepositFor(user, rootToken, amount);
    }
}
