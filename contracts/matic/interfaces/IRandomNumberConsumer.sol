//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @notice Interface to consume random number from a random number generator contract
 */
interface IRandomNumberConsumer {
    function getRandomNumber() external returns (bytes32);
}
