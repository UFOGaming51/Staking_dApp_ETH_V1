//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IStaking {
    function initialize(
        address _stakingToken,
        uint256 _lockinBlocks,
        address _operator,
        bool _isFlexiPool
    ) external;

    function claimPlasmaFromFactory(
        uint256[] calldata depositNumbers,
        address depositor,
        address plasmaRecipient
    ) external;

    function deposit(uint256 amount) external;

    function depositTo(address _to, uint256 amount) external;
}
