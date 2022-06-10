//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 @notice NFT UFO contract function
 @dev The interface only currently contains only breeding function. Any other functions can be added as per requirement
 */
interface IUFO {
    function canBreed(uint256 ufo1, uint256 ufo2) external view returns (bool);

    function CreateChild(
        uint256 ufo1,
        uint256 ufo2,
        address receiver
    ) external;
}
