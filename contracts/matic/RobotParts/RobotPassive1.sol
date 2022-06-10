//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import './RobotPart.sol';

/**
 * @notice Robot Passive 1 NFT contract
 */
contract RobotPassive1 is Initializable, RobotPart {
    constructor() initializer {}

    /**
     * @notice Initialize the Robot Ability Passive 2 NFT contract
     * @dev Change the Levels and Powers to be adjusted as per number documentation
     * @param _admin admin
     * @param _uap UAP token address
     * @param _ufo UFO token address
     */
    function initialize(
        address _admin,
        address _uap,
        address _ufo
    ) public override initializer {
        __ERC721_init('Robot Passive 1', 'RobotPassive1');
        admin = _admin;
        powerDecimals = 0;

        uapTokenContract = IERC20Burnable(_uap);
        ufoTokenContract = IERC20Burnable(_ufo);

        Level[] memory WhiteLevels = new Level[](5);
        uint128[] memory WhitePowers = new uint128[](5);

        WhiteLevels[0] = Level.Zero;
        WhiteLevels[1] = Level.One;
        WhiteLevels[2] = Level.Two;
        WhiteLevels[3] = Level.Three;
        WhiteLevels[4] = Level.Four;

        WhitePowers[0] = 300;
        WhitePowers[1] = 600;
        WhitePowers[2] = 900;
        WhitePowers[3] = 1200;
        WhitePowers[4] = 3000;

        _populatepowerTable(Rarity.White, WhiteLevels, WhitePowers);

        Level[] memory GreenLevels = new Level[](5);
        uint128[] memory GreenPowers = new uint128[](5);

        GreenLevels[0] = Level.Zero;
        GreenLevels[1] = Level.One;
        GreenLevels[2] = Level.Two;
        GreenLevels[3] = Level.Three;
        GreenLevels[4] = Level.Four;

        GreenPowers[0] = 360;
        GreenPowers[1] = 810;
        GreenPowers[2] = 1560;
        GreenPowers[3] = 2760;
        GreenPowers[4] = 4860;

        _populatepowerTable(Rarity.Green, GreenLevels, GreenPowers);

        Level[] memory BlueLevels = new Level[](6);
        uint128[] memory BluePowers = new uint128[](6);

        BlueLevels[0] = Level.Zero;
        BlueLevels[1] = Level.One;
        BlueLevels[2] = Level.Two;
        BlueLevels[3] = Level.Three;
        BlueLevels[4] = Level.Four;
        BlueLevels[5] = Level.Five;

        BluePowers[0] = 600;
        BluePowers[1] = 1050;
        BluePowers[2] = 1950;
        BluePowers[3] = 3300;
        BluePowers[4] = 5700;
        BluePowers[5] = 8700;

        _populatepowerTable(Rarity.Blue, BlueLevels, BluePowers);

        Level[] memory PurpleLevels = new Level[](6);
        uint128[] memory PurplePowers = new uint128[](6);

        PurpleLevels[0] = Level.Zero;
        PurpleLevels[1] = Level.One;
        PurpleLevels[2] = Level.Two;
        PurpleLevels[3] = Level.Three;
        PurpleLevels[4] = Level.Four;
        PurpleLevels[5] = Level.Five;

        PurplePowers[0] = 1050;
        PurplePowers[1] = 1650;
        PurplePowers[2] = 2700;
        PurplePowers[3] = 4500;
        PurplePowers[4] = 8100;
        PurplePowers[5] = 13200;

        _populatepowerTable(Rarity.Purple, PurpleLevels, PurplePowers);
    }

    /**
     * @notice Return the number of UAP tokens requried for NFT to upgrade to next Level
     * @dev The function needs to be updated when further documenation is provided
     * @param nftId ID of the NFT
     * @return UAP required for next Level Upgrade
     */
    function uapRequiredForNextUpgrade(uint256 nftId) public view override returns (uint256) {
        require(_exists(nftId), 'Only Minted NFTs can be updated');
        NftPowerProperty memory property = nftProperites[nftId];
        if (property.rarity == Rarity.White || property.rarity == Rarity.Green) {
            require(property.level != Level.Four, 'White and Green rarity NFT have max level Four');
        } else {
            require(property.level != Level.Five, 'Blue and Purple rarity NFT have max level Five');
        }
        return 100; // temp, change in switch/if-else condition
    }

    /**
     * @notice Return the number of UFO tokens required for NFT to upgrade to next level
     * @dev The function needs to be updated when further documentation is provided
     * @param nftId ID of the NFT
     * @return UFO tokens required for next Level Updgrade
     */
    function ufoRequiredForNextUpgrade(uint256 nftId) public view override returns (uint256) {
        // get this from team
        return totalSupply() + (1) + (nftId) * (10**18);
    }
}
