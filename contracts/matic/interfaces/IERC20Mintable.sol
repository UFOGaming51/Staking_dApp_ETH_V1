//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @notice Interface for minting any ERC20 token
 */
interface IERC20Mintable {
    function mint(address _to, uint256 _amount) external returns (uint256);
}
