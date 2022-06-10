//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @notice Interface for fetching the allocation provided by the plasma counter
 * @dev It may become depricated as per the new plasma contract design
 */
interface IPlasmaCounter {
    function getAllocationFraction(address _stakingContract) external view returns (uint256 num, uint256 den);
}
