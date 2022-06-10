//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '../RareNFT.sol';

/**
 * @notice Robot Part abstract contract. Makes sure the robot parts are not transferable from one UFO to another
 */
abstract contract RobotPart is RareNFT {
    /**
     * @notice Override the _transfer function and makes the robot parts non-transferable
     */
    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        revert('Robot Parts are non-transferable');
    }
}
