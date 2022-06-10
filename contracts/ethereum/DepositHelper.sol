//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './interfaces/IStaking.sol';

contract DepositHelper {
    IERC20Upgradeable public immutable ufoToken;
    IERC20Upgradeable public immutable lpToken;

    address[] public allUfoPools;
    address[] public allLpPools;

    constructor(
        address[] memory _allUfoPools,
        address[] memory _allLpPools,
        IERC20Upgradeable _ufoToken,
        IERC20Upgradeable _lpToken
    ) {
        for (uint256 index = 0; index < _allLpPools.length; index++) {
            address pool = _allLpPools[index];
            _lpToken.approve(pool, type(uint256).max);
        }

        for (uint256 index = 0; index < _allUfoPools.length; index++) {
            address pool = _allUfoPools[index];
            _ufoToken.approve(pool, type(uint256).max);
        }

        ufoToken = _ufoToken;
        lpToken = _lpToken;

        allLpPools = _allLpPools;
        allUfoPools = _allUfoPools;
    }

    function depositUfoToPool(address pool, uint256 amount) external {
        ufoToken.transferFrom(msg.sender, address(this), amount);
        IStaking(pool).depositTo(msg.sender, amount);
    }

    function depositLpToPool(address pool, uint256 amount) external {
        lpToken.transferFrom(msg.sender, address(this), amount);
        IStaking(pool).depositTo(msg.sender, amount);
    }

    function resetAllowanes() external {
        for (uint256 index = 0; index < allLpPools.length; index++) {
            address pool = allLpPools[index];
            lpToken.approve(pool, type(uint256).max);
        }

        for (uint256 index = 0; index < allUfoPools.length; index++) {
            address pool = allUfoPools[index];
            ufoToken.approve(pool, type(uint256).max);
        }
    }
}
