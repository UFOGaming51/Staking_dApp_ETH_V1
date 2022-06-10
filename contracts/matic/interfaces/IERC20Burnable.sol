//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @notice Interface for standard burn/burnFrom function for ERC20 tokens
 */
interface IERC20Burnable {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}
