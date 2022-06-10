//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @notice Chainlink VRF consumer. The contract must contain some LINK tokens against it for random number to be fetched from VRF
 */
contract RandomNumberConsumer is VRFConsumerBase, Ownable {
    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;

    mapping(address => bool) public verifiedConsumers;

    // VRFConsumerBase(
    //     0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator (varies by network)
    //     0x514910771AF9Ca656af840dff83E8264EcF986CA // LINK Token (varies by network)
    // )
    // keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;

    /**
     * @notice The keyhash, VRF co-ordinator address and link token address will change as per network
     * @dev -----
     * @param owner Owner of the contract
     * @param _vrfCoordinator address of the VRF Coordinator
     * @param _linkToken addres of the link token
     * @param _keyHash KeyHash
     */
    constructor(
        address owner,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) Ownable() {
        super.transferOwnership(owner);
        keyHash = _keyHash;
        fee = 2 * 10**18; // 2 LINK (Varies by network)
    }

    /**
     * @notice Generate a random number
     * @return requestId
     */
    function getRandomNumber() external onlyVerifiedConsumer(msg.sender) returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, 'Not enough LINK - fill contract with faucet');
        return requestRandomness(keyHash, fee);
    }

    /**
     * @notice Fullfill randomness
     */
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        randomResult = randomness;
    }

    /**
     * @notice Add a verified consumer. Only verified consumers can fetch the random number from the contract
     * @param _consumer Address of the consumer
     */
    function addVerifierConsumer(address _consumer) external onlyOwner {
        verifiedConsumers[_consumer] = true;
    }

    /**
     * @notice Removes consumer
     * @param _consumer Address of the consumer
     */
    function removeConsumer(address _consumer) external onlyOwner {
        verifiedConsumers[_consumer] = false;
    }

    /**
     * @notice Lets the functions to be only called by a verified consumer
     * @param _consumer Address of the cosumer
     */
    modifier onlyVerifiedConsumer(address _consumer) {
        require(verifiedConsumers[_consumer], 'Only Verified consumer can call this');
        _;
    }

    function withdrawLink() external {}
}
