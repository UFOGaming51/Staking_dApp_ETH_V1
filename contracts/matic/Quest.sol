//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol';

import './UFO/UFO.sol';

/**
 * @notice Quest Contract
 */
contract Quest is Initializable, ERC721HolderUpgradeable {
    address public admin;
    address public gameServer;

    UFO public ufoNFTContract;

    uint256 public maxQuestsPerDay;
    mapping(bytes32 => bool) public completedQuests;
    mapping(uint256 => mapping(bytes32 => bool)) questCompletedByUFO; // nftId => questId => boolean
    mapping(uint256 => mapping(uint256 => uint256)) numberOfQuestsByUFOPerDay; // nftid => day => quests

    uint256[50] private __gap;

    /**
     * @notice Initialize the Quest Contract
     * @param _ufoNFT ERC721 NFT contract
     * @param _admin address of the admin contract
     * @param _gameServer address of the gameServer. This address will be updating the quests in the contract
     * @param _maxQuestsPerDay maximum number of quests that a UFO can play in a day
     */
    function initialize(
        address _ufoNFT,
        address _admin,
        address _gameServer,
        uint256 _maxQuestsPerDay
    ) public initializer {
        ufoNFTContract = UFO(_ufoNFT);
        admin = _admin;
        gameServer = _gameServer;
        maxQuestsPerDay = _maxQuestsPerDay;
    }

    /**
     * @notice Checks whether the given quests can be added to the UFO
     * @param nftd ID of the NFT
     * @param questId ID of the quest
     */
    function _canAddQuestToUFO(uint256 nftd, bytes32 questId) internal view returns (bool) {
        return (!completedQuests[questId] && !questCompletedByUFO[nftd][questId]);
    }

    /**
     * @notice Registers the quests and updates the UFO and its rewards. The function can be called only by the gameserver
     * @param nftIds IDs of the NFT that need to called
     * @param quests Quests completed by each NFT
     * @dev Modify the function to use multi-call to reduce the transaction cost
     */
    function registerQuestsAndUpdateUFO(uint256[] calldata nftIds, bytes32[][] calldata quests) external onlyGameServer {
        require(nftIds.length == quests.length, 'Arity mistmatch');
        for (uint256 index = 0; index < nftIds.length; index++) {
            _updateQuestSingleUfo(nftIds[index], quests[index]);
        }
    }

    // calls UFO contracts for UAP and rating update
    /**
     * @notice Internal function to update the quests for a single NFT
     * @param nftId ID of the NFT
     * @param quests Quests completed by the NFT
     */
    function _updateQuestSingleUfo(uint256 nftId, bytes32[] calldata quests) internal {
        uint256 day = block.timestamp / (1 days);
        if (numberOfQuestsByUFOPerDay[nftId][day] >= maxQuestsPerDay) {
            ufoNFTContract.addQuest(nftId, 0);
            return;
        } else {
            uint256 questsRemaining = maxQuestsPerDay - numberOfQuestsByUFOPerDay[nftId][day];
            numberOfQuestsByUFOPerDay[nftId][day] = numberOfQuestsByUFOPerDay[nftId][day] + (questsRemaining);

            for (uint256 index = 0; index < quests.length; index++) {
                bytes32 quest = quests[index];
                require(!questCompletedByUFO[nftId][quest], 'Quest is already completed by NFT');
                questCompletedByUFO[nftId][quest] = true;
                require(!completedQuests[quest], 'Quest is already completed by another NFT');
                completedQuests[quest] = true;
            }

            ufoNFTContract.addQuest(nftId, questsRemaining);
        }
    }

    modifier onlyGameServer() {
        require(msg.sender == gameServer, 'Only Game Server can change update');
        _;
    }
}
