//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IStakingFactory {
    function updateTVL(uint256 tvl) external;

    function flushReward(address user, uint256 amount) external;

    function getTotalTVLWeight() external view returns (uint256 lockedPoolTvlWeight, uint256 unlockedPoolTvlWeight);

    function getPoolShare(address pool) external view returns (uint256 amount);

    function getTotalTVL() external view returns (uint256 totalLockedUfo);

    function getPlasmaPerBlock() external view returns (uint256 plasmaPerBlock);

    function updateClaimedRewards(uint256 amount) external;

    function updateClaimedPlasma(uint256 amount) external;
}
