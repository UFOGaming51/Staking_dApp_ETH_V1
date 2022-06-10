//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';

import './interfaces/IRare.sol';
import './interfaces/IERC20Burnable.sol';

import './UFO/UFO.sol';

/**
 * @notice Breeder Contract
 */
contract Breeder is Initializable, ERC721HolderUpgradeable, IRare {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct BreedingCell {
        uint256 ufo1;
        uint256 ufo2;
        uint256 unlockTime;
        address receiver;
        address requestCreator;
        uint256 ufoTokenRequired;
        uint256 uapTokenRequired;
    }

    address public admin;

    UFO public ufoNFTContract;
    address public uapTokenContract;
    address public ufoTokenContract;

    uint256 public lockTime;

    mapping(uint256 => BreedingCell) breedingRoom;
    uint256 public breedingRoomCounter;

    event ChangeLockTime(uint256 newLockTime);
    event StartBreeding(uint256 indexed ufo1, uint256 indexed ufo2, uint256 releaseTime);
    event CancelBreeding(uint256 indexed breedingCellNumber, uint256 indexed ufo1, uint256 ufo2);
    event CompleteBreeding(uint256 indexed breedingCellNumber, uint256 indexed ufo1, uint256 ufo2);

    /**
     * @notice Initialize the Breeder contract
     * @param _admin Admin of the contract
     * @param _ufoNTF Address of the UFO NFT contract
     * @param _ufoToken Address of the UFO ERC20 contract
     * @param _uapToken Address of the UAP ERC20 contract
     */
    function initialize(
        address _admin,
        address _ufoNTF,
        address _ufoToken,
        address _uapToken
    ) public initializer {
        admin = _admin;
        ufoNFTContract = UFO(_ufoNTF);
        lockTime = 7 days;
        ufoTokenContract = _ufoToken;
        uapTokenContract = _uapToken;

        __ERC721Holder_init();
    }

    /**
     * @notice Change Admin address
     * @dev Use OwnableUpgradable contract and replace this
     * @param _admin Address of the new admin
     */
    function changeAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    /**
     * @notice Change the locktime for NFT Breeding
     * @param newLockTime New Lock Time
     */
    function changeLockTimeDays(uint256 newLockTime) external onlyAdmin {
        lockTime = newLockTime * (1 days);
        emit ChangeLockTime(newLockTime);
    }

    /**
     * @notice Set The UFO NFT contract
     * @param _ufoContract Address of the UFO NFT contract
     */
    function setUfoContract(address _ufoContract) external onlyAdmin {
        ufoNFTContract = UFO(_ufoContract);
    }

    /**
     * @notice Lock the NFT tokens for breeding
     * @param ufo1 ID of the first NFT to breed
     * @param ufo2 ID of the second NFT to breed
     * @param _receiver Address that receives the newly minted NFT
     */
    function lockUFOsForBreeding(
        uint256 ufo1,
        uint256 ufo2,
        address _receiver
    ) external {
        require(ufo1 != ufo2, "Same UFOs can't breed");
        require(ufoNFTContract.ownerOf(ufo1) == msg.sender, 'Only owner of ufo can breed');
        require(ufoNFTContract.ownerOf(ufo2) == msg.sender, 'Only owner of ufo can breed');

        ufoNFTContract.safeTransferFrom(msg.sender, address(this), ufo1);
        ufoNFTContract.safeTransferFrom(msg.sender, address(this), ufo2);

        uint256 _ufoTokensRequired = ufoRequiredForBreeding();
        uint256 _uapTokensRequired = uapRequiredForBreeding();

        IERC20Upgradeable(ufoTokenContract).safeTransferFrom(msg.sender, address(this), _ufoTokensRequired);
        IERC20Upgradeable(uapTokenContract).safeTransferFrom(msg.sender, address(this), _uapTokensRequired);

        breedingRoomCounter = breedingRoomCounter + (1);
        uint256 releaseTime = block.timestamp + (lockTime);
        breedingRoom[breedingRoomCounter] = BreedingCell(
            ufo1,
            ufo2,
            releaseTime,
            _receiver,
            msg.sender,
            ufoRequiredForBreeding(),
            uapRequiredForBreeding()
        );
        emit StartBreeding(ufo1, ufo2, releaseTime);
    }

    /**
     * @notice Complete the ownsership transfer for child NFT
     * @param breedingCellNumber number of breeding cell to release.
     */
    function getChildUfo(uint256 breedingCellNumber) external {
        require(breedingRoom[breedingCellNumber].receiver == msg.sender, 'Only receiver address can new UFO');
        require(block.timestamp > breedingRoom[breedingCellNumber].unlockTime, "Can't get child UFO while parents are breeding");

        ufoNFTContract.createOtherNFT(msg.sender);

        ufoNFTContract.approve(msg.sender, breedingRoom[breedingCellNumber].ufo1);
        ufoNFTContract.approve(msg.sender, breedingRoom[breedingCellNumber].ufo2);

        IERC20Burnable(ufoTokenContract).burn(breedingRoom[breedingCellNumber].ufoTokenRequired);
        IERC20Burnable(uapTokenContract).burn(breedingRoom[breedingCellNumber].uapTokenRequired);

        emit CompleteBreeding(breedingCellNumber, breedingRoom[breedingCellNumber].ufo1, breedingRoom[breedingCellNumber].ufo2);
        delete breedingRoom[breedingCellNumber];
    }

    /**
     * @notice Release the NFT without breeding. If breeding ritual needs to be called in the middle
     * @param breedingCellNumber The breeding cell number to be released
     */
    function releaseUfoWithoutBreeding(uint256 breedingCellNumber) external {
        require(breedingRoom[breedingCellNumber].requestCreator == msg.sender, 'Only receiver address can new UFO');
        ufoNFTContract.approve(msg.sender, breedingRoom[breedingCellNumber].ufo1);
        ufoNFTContract.approve(msg.sender, breedingRoom[breedingCellNumber].ufo2);

        IERC20Upgradeable(ufoTokenContract).safeTransfer(msg.sender, breedingRoom[breedingCellNumber].ufoTokenRequired);
        IERC20Upgradeable(uapTokenContract).safeTransfer(msg.sender, breedingRoom[breedingCellNumber].uapTokenRequired);

        emit CancelBreeding(breedingCellNumber, breedingRoom[breedingCellNumber].ufo1, breedingRoom[breedingCellNumber].ufo2);
        delete breedingRoom[breedingCellNumber];
    }

    /**
     * @notice Returns the number of UFO for breeding
     * @dev The function needs to be written once the specs are provided
     */
    function ufoRequiredForBreeding() public pure returns (uint256) {
        return 10**18;
    }

    /**
     * @notice Returns the number of UAP for breeding
     * @dev The function needs to be written once the specs are provided
     */
    function uapRequiredForBreeding() public pure returns (uint256) {
        return 2 * (10**18);
    }

    /**
     * @notice callback. The logic inside that ensure that only relevant NFTs help
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        // to be complete
        require(msg.sender == address(ufoNFTContract), 'Only UFO contract can be help in the breeding contract');
        return this.onERC721Received.selector;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'Only admin can call');
        _;
    }
}
