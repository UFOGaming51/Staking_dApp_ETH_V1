//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import './interfaces/IERC20Burnable.sol';
import './interfaces/IRare.sol';

/**
 * @notice RareNFT contract. The contract when inherited gives the gaming related properties to each NFT
 */
abstract contract RareNFT is ERC721EnumerableUpgradeable, IRare {
    address public admin; // admin will be a multisig contract address
    uint256 public powerDecimals;

    IERC20Burnable public uapTokenContract;
    IERC20Burnable public ufoTokenContract;

    mapping(uint256 => NftPowerProperty) public nftProperites;
    mapping(Rarity => mapping(Level => uint128)) public powerTable;

    uint256[50] private __gap;

    event UpgradedNFT(uint256 nftId, Rarity rarity, Level level);

    /**
     * @notice Initialize the contract
     * @param _admin address of the admin
     * @param _uap address of the uap token
     * @param _ufo address of the ufo token
     */
    function initialize(
        address _admin,
        address _uap,
        address _ufo
    ) public virtual;

    /**
     * @notice Return the number of UAP tokens requried for NFT to upgrade to next Level
     * @dev The function needs to be updated when further documenation is provided
     * @param nftId ID of the NFT
     * @return UAP required for next Level Upgrade
     */
    function uapRequiredForNextUpgrade(uint256 nftId) public view virtual returns (uint256);

    /**
     * @notice Return the number of UFO tokens required for NFT to upgrade to next level
     * @dev The function needs to be updated when further documentation is provided
     * @param nftId ID of the NFT
     * @return UFO tokens required for next Level Updgrade
     */
    function ufoRequiredForNextUpgrade(uint256 nftId) public view virtual returns (uint256);

    /**
     * @notice Return the power of the given NFT
     * @param nftId ID of the NFT
     */
    function getPower(uint256 nftId) public view returns (uint256) {
        return powerTable[nftProperites[nftId].rarity][nftProperites[nftId].level];
    }

    /**
     * @notice Upgrade A RareNFt
     * @param nftId ID of the NFT
     */
    function upgradeNFT(uint256 nftId) external {
        uint256 uapRequired = uapRequiredForNextUpgrade(nftId);
        uint256 ufoRequired = ufoRequiredForNextUpgrade(nftId);

        uapTokenContract.burnFrom(msg.sender, uapRequired);
        ufoTokenContract.burnFrom(msg.sender, ufoRequired);

        NftPowerProperty memory property = nftProperites[nftId];
        if (property.level == Level.Zero) {
            nftProperites[nftId].level = Level.One;
        } else if (property.level == Level.One) {
            nftProperites[nftId].level = Level.Two;
        } else if (property.level == Level.Two) {
            nftProperites[nftId].level = Level.Three;
        } else if (property.level == Level.Three) {
            nftProperites[nftId].level = Level.Four;
        } else if (property.level == Level.Four) {
            nftProperites[nftId].level = Level.Five;
        } else {
            revert('No NFT can have Level more than Five');
        }

        emit UpgradedNFT(nftId, nftProperites[nftId].rarity, nftProperites[nftId].level);
    }

    /**
     * @notice Populate the power table
     * @param rarity Rarity of the NFT
     * @param levels All possible levels in the given rarity
     * @param powers Powers associated wth each level
     */
    function _populatepowerTable(
        Rarity rarity,
        Level[] memory levels,
        uint128[] memory powers
    ) internal {
        require(levels.length == powers.length, 'Arity mismatch');

        for (uint256 index = 0; index < levels.length; index++) {
            powerTable[rarity][levels[index]] = powers[index];
        }
    }

    /**
     * @notice Create a new NFT
     * @param rarity Rarity the NFT to be created
     * @param _to address that receives the newly generated NFT
     */
    function createNew(Rarity rarity, address _to) external onlyAdmin returns (uint256) {
        uint256 newID = totalSupply() + (1);

        nftProperites[newID].rarity = rarity;
        nftProperites[newID].level = Level.Zero;

        uint128 _power = powerTable[rarity][Level.Zero];
        require(_power != 0, 'NFT not registered');

        _safeMint(_to, newID);
        return newID;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'Only admin can call');
        _;
    }
}
