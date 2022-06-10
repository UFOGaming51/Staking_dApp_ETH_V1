//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol';

import './RandomnessGenerator.sol';
import './RatingManager.sol';

import '../interfaces/IERC20Burnable.sol';
import '../interfaces/IERC20Mintable.sol';
import '../interfaces/IRare.sol';

import '../RobotParts/RobotAbility1.sol';
import '../RobotParts/RobotAbility2.sol';
import '../RobotParts/RobotPassive1.sol';
import '../RobotParts/RobotPassive2.sol';
import '../RobotParts/RobotPassive3.sol';
import '../RobotParts/RobotAbilityMelee.sol';

/**
 * @notice UFO NFT Contract
 */
contract UFO is Initializable, ERC721EnumerableUpgradeable, ERC721HolderUpgradeable, RandomnessGenerator, RatingManager, IRare {
    struct Robot {
        uint256 ability1;
        uint256 ability2;
        uint256 passive1;
        uint256 passive2;
        uint256 passive3;
        uint256 abilityMelee;
        string name;
        uint256 rating;
        uint256 lastUpdatedAt;
        bool paused;
        uint256 pendingUAP;
    }

    RobotAbility1 public robotAbility1;
    RobotAbility2 public robotAbility2;
    RobotPassive1 public robotPassive1;
    RobotPassive2 public robotPassive2;
    RobotPassive3 public robotPassive3;
    RobotAbilityMelee public robotAbilityMelee;

    mapping(uint256 => Robot) public UfoStorage;
    mapping(uint256 => mapping(uint256 => bool)) ratingUpdatedForDay;

    address public admin; // admin will be a multisig contract address
    address public quest;
    address public breeder;

    IERC20Burnable public uapBurnTokenContract;
    IERC20Burnable public ufoBurnTokenContract;
    IERC20Mintable public uapMintTokenContract;

    uint256[50] private __gap;

    /**
     * @notice Initializes the UFO NFT contract with dependent parameters
     * @param _admin Address of the admin contract
     * @param _uap Address of UAP token
     * @param _ufo Address of the UFO ERC20 token
     * @param _quest Address of the quest contract
     * @param _breeder address of the breeding contract
     * @param _randomNumberConsumer address of the random number consumer contract
     * @param _robotAbility1 Address of the Robot Ability 1
     * @param _robotAbility2 Address of the Robot Ability 2
     * @param _robotPassive1 Address of the Robot Passive 1
     * @param _robotPassive2 Address of the Robot Passive 2
     * @param _robotPassive3 Address of the Robot Passive 3
     * @param _robotAbilityMelee Address of the Robot Ability Melee
     */
    function initialize(
        address _admin,
        address _uap,
        address _ufo,
        address _quest,
        address _breeder,
        address _randomNumberConsumer,
        address _robotAbility1,
        address _robotAbility2,
        address _robotPassive1,
        address _robotPassive2,
        address _robotPassive3,
        address _robotAbilityMelee
    ) public initializer {
        __ERC721_init('UFO', 'UFO');
        RandomnessGenerator__init(100000, _randomNumberConsumer);
        RatingManager__Init(_admin, 3 days, 3, 2);
        __ERC721Holder_init();

        admin = _admin;
        uapBurnTokenContract = IERC20Burnable(_uap);
        ufoBurnTokenContract = IERC20Burnable(_ufo);
        quest = _quest;
        breeder = _breeder;

        robotAbility1 = RobotAbility1(_robotAbility1);
        robotAbility2 = RobotAbility2(_robotAbility2);
        robotPassive1 = RobotPassive1(_robotPassive1);
        robotPassive2 = RobotPassive2(_robotPassive2);
        robotPassive3 = RobotPassive3(_robotPassive3);
        robotAbilityMelee = RobotAbilityMelee(_robotAbilityMelee);

        for (uint256 index = 0; index < 9; index++) {
            _createGenesis();
        }
    }

    /**
     * @notice function call to generate a child NFT. Only breeder contract can call
     * @param receiver Address that receives the newly generated NFT
     * @return newly generated NFT ID
     */
    function createOtherNFT(address receiver) external onlyBreeder returns (uint256) {
        return _createOtherNFT(receiver);
    }

    /**
     * @notice function call to generate a child NFT. Only breeder contract can call
     * @param _receiver Address that receives the newly generated NFT
     */
    function _createOtherNFT(address _receiver) internal returns (uint256) {
        uint256 newID = totalSupply() + (1);
        Robot memory robot;
        robot.name = _generateName(newID);
        robot.ability1 = robotAbility1.createNew(Rarity.Green, address(this));
        robot.ability2 = robotAbility2.createNew(Rarity.Green, address(this));
        robot.passive1 = robotPassive1.createNew(Rarity.Green, address(this));
        robot.passive2 = robotPassive2.createNew(Rarity.Green, address(this));
        robot.passive3 = robotPassive3.createNew(Rarity.Green, address(this));
        robot.abilityMelee = robotAbilityMelee.createNew(Rarity.Green, address(this));
        robot.rating = _getRandomRating(newID);
        robot.lastUpdatedAt = block.timestamp;

        UfoStorage[newID] = robot;
        _safeMint(_receiver, newID);
        return newID;
    }

    /**
     * @notice Create Genesis NFTs
     * @return newly generated NFT ID
     */
    function _createGenesis() internal returns (uint256) {
        uint256 newID = totalSupply() + (1);
        Robot memory robot;
        robot.name = _generateName(newID);
        robot.ability1 = robotAbility1.createNew(Rarity.Purple, address(this));
        robot.ability2 = robotAbility2.createNew(Rarity.Purple, address(this));
        robot.passive1 = robotPassive1.createNew(Rarity.Purple, address(this));
        robot.passive2 = robotPassive2.createNew(Rarity.Purple, address(this));
        robot.passive3 = robotPassive3.createNew(Rarity.Purple, address(this));
        robot.abilityMelee = robotAbilityMelee.createNew(Rarity.Purple, address(this));
        robot.rating = _getRandomRating(newID);
        robot.lastUpdatedAt = block.timestamp;

        UfoStorage[newID] = robot;
        _safeMint(admin, newID);
        return newID;
    }

    // address operator, address from, uint256 tokenId, bytes memory
    /**
     * @notice callback. The logic inside that ensure that only relevant NFTs help
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public view override returns (bytes4) {
        require(
            msg.sender == address(robotAbility1) ||
                msg.sender == address(robotAbility2) ||
                msg.sender == address(robotPassive1) ||
                msg.sender == address(robotPassive2) ||
                msg.sender == address(robotPassive3) ||
                msg.sender == address(robotAbilityMelee),
            'UFO contract can only hold Robot Parts and no other tokens'
        );
        return this.onERC721Received.selector;
    }

    /**
     * @notice The the latest rating of UFO
     * @param nftId ID of the NFT
     */
    function getLatestRating(uint256 nftId) public view returns (uint256) {
        require(_exists(nftId), "NFT doesn't exists");
        return _getRating(UfoStorage[nftId].paused, UfoStorage[nftId].rating, UfoStorage[nftId].lastUpdatedAt);
    }

    /**
     * @notice Add quest related information to the NFT. Can only be called by quest contract
     * @param nftId ID of the NFT
     * @param questsToAdd Number of quests to add against the NFT
     */
    function addQuest(uint256 nftId, uint256 questsToAdd) external onlyQuest {
        require(_exists(nftId), "NFT doesn't exists");
        uint256 latestRating = getLatestRating(nftId);
        _updatingRating(nftId, latestRating);

        if (questsToAdd != 0) {
            uint256 uapPerQuest = getUAPForRating(latestRating);
            UfoStorage[nftId].pendingUAP = UfoStorage[nftId].pendingUAP + (uapPerQuest);
        }

        uint256 day = block.timestamp / (1 days);
        if (!ratingUpdatedForDay[nftId][day]) {
            UfoStorage[nftId].rating = UfoStorage[nftId].rating + (ratingIncrementPerDay);
            ratingUpdatedForDay[nftId][day] = false;
        }
    }

    /**
     * @notice Internal function to update the rating of the NFT
     * @param nftId ID of the NFT
     * @param rating latest rating of the NFT
     */
    function _updatingRating(uint256 nftId, uint256 rating) internal {
        UfoStorage[nftId].rating = rating;
        UfoStorage[nftId].lastUpdatedAt = block.timestamp;
    }

    modifier onlyQuest() {
        require(msg.sender == quest, 'Only Quest Contract can call');
        _;
    }

    modifier onlyBreeder() {
        require(msg.sender == breeder, 'Only Breeder Contract can call');
        _;
    }
}
