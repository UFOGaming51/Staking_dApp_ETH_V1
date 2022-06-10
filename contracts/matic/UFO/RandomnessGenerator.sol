//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import '../interfaces/IRandomNumberConsumer.sol';

/**
 * @notice Random number generator
 */
contract RandomnessGenerator is Initializable {
    struct slice {
        uint256 _len;
        uint256 _ptr;
    }

    /**
     * @notice List of letter that will be used to generate the name of the NFT
     */
    string[] public nameGeneratorSet;

    /**
     * @notice Maximum Rating when NFT is created
     */
    uint256 public maxRatingAtInit;

    /**
     * @notice address of the random number consumer contract
     */
    IRandomNumberConsumer public randomNumberConsumer;

    mapping(uint256 => uint256) private randomNumberAtBlock;
    uint256[50] private __gap;

    /**
     * @notice Initialize Randomness generator contract
     * @param _maxRatingAtInit Maximum Rating when any NFT is initialized
     * @param _randomNumberConsumer Address of the random number consumer contract
     */
    function RandomnessGenerator__init(uint256 _maxRatingAtInit, address _randomNumberConsumer) public initializer {
        nameGeneratorSet = ['h', '0', 'i', 'u', 'e', 'g', 'f', 'd', '0', 'e', '2', '8', 'f', 'g', '3', 'e', 'f', 'o', 'u', 'g'];
        maxRatingAtInit = _maxRatingAtInit;
        randomNumberConsumer = IRandomNumberConsumer(_randomNumberConsumer);
    }

    /**
     * @notice Generate a random rating
     * @param randomizer Increase the entropy of the random number
     * @return Rating
     */
    function _getRandomRating(uint256 randomizer) internal returns (uint256) {
        return uint256(maxRatingAtInit) + (_getRandomness(randomizer) % 100000);
    }

    /**
     * @notice Generate randomness that can be used by any
     * @param randomizer Increase the entropy of the random number
     * @return A random number
     */
    function _getRandomness(uint256 randomizer) internal returns (uint256) {
        if (randomNumberAtBlock[block.number] == 0) {
            randomNumberAtBlock[block.number] = uint256(randomNumberConsumer.getRandomNumber());
        }

        return uint256(keccak256(abi.encode(randomNumberAtBlock[block.number], randomizer)));
    }

    /**
     * @notice Generate Name
     * @param randomizer Increase the entropy of the random number
     * @return string A random onchain generator
     */
    function _generateName(uint256 randomizer) internal returns (string memory) {
        uint256 nameGeneratorPrefix = uint256(keccak256(abi.encodePacked('UFO Name Generator prefix')));
        uint256 randomness = _getRandomness(randomizer);
        string memory name;
        for (uint256 index = 0; index < 5; index++) {
            uint256 charIndex = uint256(keccak256(abi.encodePacked(nameGeneratorPrefix, randomness, index))) % nameGeneratorSet.length;
            name = concat(name, nameGeneratorSet[charIndex]);
        }
        return name;
    }

    /**
     * @notice Concat to strings
     * @dev Can be optimized by using abi.encode(args);
     * @param _self First string
     * @param _other Second string
     * @return Concated string
     */
    function concat(string memory _self, string memory _other) internal pure returns (string memory) {
        slice memory self = toSlice(_self);
        slice memory other = toSlice(_other);
        string memory ret = new string(self._len + other._len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /**
     * @notice Create struct for string operation
     * @dev Its use can be avoided if abi.encode(arg) is used
     * @param self The string the slice
     * @return slice
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint256 ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    function memcpy(
        uint256 dest,
        uint256 src,
        uint256 len
    ) internal pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256**(32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
}
