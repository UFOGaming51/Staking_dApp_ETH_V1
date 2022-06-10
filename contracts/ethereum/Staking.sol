//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

import './interfaces/IStaking.sol';
import './interfaces/IStakingFactory.sol';
import './interfaces/IRootChainManager.sol';

import '../matic/interfaces/IERC20Mintable.sol';
import './Errors.sol';

contract Staking is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, IStaking {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum DepositState {
        NOT_CREATED,
        DEPOSITED,
        WITHDRAWN,
        REWARD_CLAIMED
    }

    struct Deposit {
        uint256 amount;
        uint256 startBlock;
        uint256 unlockBlock;
        uint256 plasmaLastClaimedAt;
        address user;
        DepositState depositState;
        uint256 vestedRewardUnlockBlock;
        uint256 vestedRewards;
    }

    /**
     * @notice Total number of blocks in one year
     */
    uint256 public constant totalBlocksPerYear = 365 * 24 * 60 * 60; // one year as a second
    // uint256 public constant totalBlocksPerYear = 1210; // for local
    // uint256 public constant totalBlocksPerYear = 120010; // for goerli

    uint256 public constant vestingLockBlocks = totalBlocksPerYear; // for mainnet and local
    // uint256 public constant vestingLockBlocks = 1; // for goerli

    /**
     * @notice Address of factory
     */
    address public factory;

    /**
     * @notice minimum number of blocks to be locked
     */
    uint256 public lockinBlocks;

    /**
     * @notice Block at which starting starts
     */
    uint256 public startBlock;

    /**
     * @notice address of staking token
     */
    address public stakingToken;

    /**
     * @notice address of plasma token
     */
    address public immutable plasmaToken;

    /**
     * @notice address of matic bridge
     */
    address public immutable maticBridge;

    /**
     * @notice address of erc20 predicate
     */
    address public immutable erc20Predicate;

    /**
     * @notice deposit counter
     */
    uint256 public depositCounter;

    /**
     * @notice total value locked
     */
    uint256 public tvl;

    /**
     * @notice deposits
     */
    mapping(uint256 => Deposit) public deposits;

    /**
     * @notice event when deposit is emitted
     */
    event Deposited(uint256 indexed depositNumber, address indexed depositor, uint256 amount, uint256 unlockBlock);

    /**
     * @notice event when plasma is claimed
     */
    event ClaimPlasma(uint256 indexed depositNumber, address indexed user, uint256 amount);

    /**
     * @notice event when deposit is withdrawn
     */
    event Withdraw(uint256 indexed depositNumber);

    /**
     * @notice event when vested reward is withdrawn
     */
    event WithdrawVestedReward(uint256 indexed depositNumber);

    /**
     * @notice event when token are withdrawn on emergency
     */
    event EmegencyWithdrawToken(uint256 indexed depositNumber);

    /**
     * @notice event Plasma Per Block is emitted
     */
    event UpdatePlasmaPerBlockPerToken(uint256 newReward);

    /**
     * @notice number of plasma tokens per block per staking token
     */
    uint256 public plasmaPerBlockPerToken;

    /**
     * @notice Plasma weight
     */
    uint256 public constant weightScale = 1e18;

    /**
     * @notice max number of deposits that can be operated in the single call
     */
    uint256 public constant MAX_LOOP_ITERATIONS = 100;

    /**
     * @notice Boolean parameter to indicate if the pool is flexi pool
     */
    bool isFlexiPool;

    /**
     * @param _plasmaToken Address of the plasma token
     * @param _erc20Predicate Address of the predicate contract
     * @param _maticBridge Address of the matic bridge
     */
    constructor(
        address _plasmaToken,
        address _erc20Predicate,
        address _maticBridge
    ) {
        require(_plasmaToken != address(0), Errors.SHOULD_BE_NON_ZERO);
        require(_maticBridge != address(0), Errors.SHOULD_BE_NON_ZERO);
        require(_erc20Predicate != address(0), Errors.SHOULD_BE_NON_ZERO);

        plasmaToken = _plasmaToken;

        maticBridge = _maticBridge;
        erc20Predicate = _erc20Predicate;
    }

    /**
     * @param _stakingToken address of token to stake
     * @param _lockinBlocks Minimum number of blocks the deposit should be staked
     * @param _operator Address of the staking operator
     * @param _isFlexiPool True if the current pool is flexi pool
     */
    function initialize(
        address _stakingToken,
        uint256 _lockinBlocks,
        address _operator,
        bool _isFlexiPool
    ) external override initializer {
        require(_lockinBlocks < totalBlocksPerYear, Errors.LOCK_IN_BLOCK_LESS_THAN_MIN);
        require(_operator != address(0), Errors.SHOULD_BE_NON_ZERO);
        require(_stakingToken != address(0), Errors.SHOULD_BE_NON_ZERO);

        __Ownable_init();
        transferOwnership(_operator);
        __Pausable_init();

        lockinBlocks = _lockinBlocks;
        // transfer ownership
        factory = msg.sender;
        stakingToken = _stakingToken;
        startBlock = block.timestamp;

        isFlexiPool = _isFlexiPool;
    }

    /**
     * @notice Deposit to Staking Contract, The token must be approved before this function is called
     * @param _to address that receives the tokens on behalf of
     * @param amount Amount of tokens to be staked
     */
    function depositTo(address _to, uint256 amount) external override nonReentrant {
        _depositInternal(_to, amount);
    }

    /**
     * @notice Deposit to Staking Contract, The token must be approved before this function is called
     * @param amount Amount of tokens to be staked
     */
    function deposit(uint256 amount) external override nonReentrant {
        _depositInternal(msg.sender, amount);
    }

    // actual logic of deposit(internal function)
    function _depositInternal(address _to, uint256 amount) internal {
        depositCounter++;
        uint256 timeStamp = block.timestamp;
        uint256 unlockTimeStamp = timeStamp + lockinBlocks;
        deposits[depositCounter] = Deposit(amount, timeStamp, unlockTimeStamp, timeStamp, _to, DepositState.DEPOSITED, 0, 0);
        tvl = tvl + (amount);

        emit Deposited(depositCounter, _to, amount, unlockTimeStamp);

        IERC20Upgradeable(stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        IStakingFactory(factory).updateTVL(tvl);
        _updatePlasmaPerBlockPerToken();
    }

    /**
     * @notice Claim Plasma from factory.
     * @param depositNumbers Deposit Numbers to claim plasma from
     * @param depositor Address of the depositor
     */
    function claimPlasmaFromFactory(
        uint256[] calldata depositNumbers,
        address depositor,
        address plasmaRecipient
    ) external override onlyFactory nonReentrant {
        require(depositNumbers.length <= MAX_LOOP_ITERATIONS, Errors.EXCEEDS_MAX_ITERATION);
        _updatePlasmaPerBlockPerToken();
        uint256 totalPlasmaToMint;
        for (uint256 index = 0; index < depositNumbers.length; index++) {
            totalPlasmaToMint += _claimPlasmaFromFactory(depositNumbers[index], depositor);
        }
        _mintAndSendPlasma(depositor, totalPlasmaToMint, plasmaRecipient);
    }

    /**
     * @notice internal function to claim plasm from factory contract
     * @param depositNumber Deposit number to claim plasma from
     * @param depositor Address of the depostor
     */
    function _claimPlasmaFromFactory(uint256 depositNumber, address depositor)
        internal
        onlyWhenDeposited(depositNumber)
        onlyDepositor(depositNumber, depositor)
        returns (uint256 amount)
    {
        (uint256 claimablePlasma, address user) = getClaimablePlasma(depositNumber);
        deposits[depositNumber].plasmaLastClaimedAt = _getCurrentBlockWrtEndBlock();
        amount = _claimPlasma(depositNumber, user, claimablePlasma);
    }

    function claimPlasmaMultiple(uint256[] calldata depositNumbers, address plasmaRecipient) external nonReentrant {
        uint256 totalAmount;
        _updatePlasmaPerBlockPerToken();
        for (uint256 index = 0; index < depositNumbers.length; index++) {
            totalAmount += _claimPlasmaMultiple(depositNumbers[index], msg.sender);
        }
        _mintAndSendPlasma(msg.sender, totalAmount, plasmaRecipient);
    }

    function _claimPlasmaMultiple(uint256 depositNumber, address depositor)
        internal
        onlyWhenDeposited(depositNumber)
        onlyDepositor(depositNumber, depositor)
        returns (uint256)
    {
        (uint256 claimablePlasma, address user) = getClaimablePlasma(depositNumber);
        deposits[depositNumber].plasmaLastClaimedAt = _getCurrentBlockWrtEndBlock();
        uint256 amount = _claimPlasma(depositNumber, user, claimablePlasma);
        return amount;
    }

    /**
     * @notice Withdraw Multiple Deposits
     * @param depositNumbers Deposit Numbers to withdraw
     */
    function withdrawUfoMultiple(uint256[] calldata depositNumbers, address plasmaRecipient) external {
        require(depositNumbers.length <= MAX_LOOP_ITERATIONS, Errors.EXCEEDS_MAX_ITERATION);
        _updatePlasmaPerBlockPerToken();
        uint256 totalPlasmaToClaim;
        uint256 totalTokensToWithdraw;
        uint256 vestedRewards;

        uint256 totalPoolShare = IStakingFactory(factory).getPoolShare(address(this));

        for (uint256 index = 0; index < depositNumbers.length; index++) {
            (uint256 a, uint256 b, uint256 c) = _withdrawUfoMultiple(depositNumbers[index], msg.sender, totalPoolShare);
            totalPlasmaToClaim += a;
            totalTokensToWithdraw += b;
            vestedRewards += c;
        }

        IERC20Upgradeable(stakingToken).safeTransfer(msg.sender, totalTokensToWithdraw);
        _mintAndSendPlasma(msg.sender, totalPlasmaToClaim, plasmaRecipient);
        IStakingFactory(factory).updateTVL(tvl);
        IStakingFactory(factory).updateClaimedRewards(vestedRewards);
    }

    /**
     * @notice Withdraw Multiple Deposits
     * @param depositNumbers Deposit Numbers to withdraw
     */
    function withdrawPartialUfoMultiple(
        uint256[] calldata depositNumbers,
        uint256 fraction,
        address plasmaRecipient
    ) external {
        require(isFlexiPool, Errors.ONLY_FEATURE_OF_FLEXI_POOLS);
        require(fraction < weightScale, Errors.MORE_THAN_FRACTION);
        require(depositNumbers.length <= MAX_LOOP_ITERATIONS, Errors.EXCEEDS_MAX_ITERATION);
        _updatePlasmaPerBlockPerToken();
        uint256 totalPlasmaToClaim;
        uint256 totalTokensToWithdraw;
        uint256 totalTokensToStakeBack;
        uint256 vestedRewards;

        uint256 totalPoolShare = IStakingFactory(factory).getPoolShare(address(this));

        for (uint256 index = 0; index < depositNumbers.length; index++) {
            (uint256 a, uint256 b, uint256 c, uint256 d) = _withdrawPartialUfoMultiple(
                depositNumbers[index],
                msg.sender,
                fraction,
                totalPoolShare
            );
            totalPlasmaToClaim += a;
            totalTokensToWithdraw += b;
            totalTokensToStakeBack += c;
            vestedRewards += d;
        }

        depositCounter++;
        uint256 nowTimeStamp = block.timestamp;
        uint256 unlockBlock = nowTimeStamp + lockinBlocks;
        deposits[depositCounter] = Deposit(
            totalTokensToStakeBack,
            nowTimeStamp,
            unlockBlock,
            nowTimeStamp,
            msg.sender,
            DepositState.DEPOSITED,
            0,
            0
        );

        emit Deposited(depositCounter, msg.sender, totalTokensToStakeBack, unlockBlock);

        IERC20Upgradeable(stakingToken).safeTransfer(msg.sender, totalTokensToWithdraw);
        _mintAndSendPlasma(msg.sender, totalPlasmaToClaim, plasmaRecipient);
        IStakingFactory(factory).updateTVL(tvl);
        IStakingFactory(factory).updateClaimedRewards(vestedRewards);
    }

    /**
     * @notice internal function to withdraw multple deposits/UFO tokens
     * @param depositNumber Deposit Number to withdraw
     * @param depositor Address of the depositor
     */
    function _withdrawPartialUfoMultiple(
        uint256 depositNumber,
        address depositor,
        uint256 fraction,
        uint256 totalPoolShare
    )
        internal
        onlyWhenDeposited(depositNumber)
        onlyDepositor(depositNumber, depositor)
        returns (
            uint256 plasmToClaim,
            uint256 stakedTokensToWithdraw,
            uint256 stakedTokensToBeAddedBack,
            uint256 vestedRewardsObtained
        )
    {
        Deposit storage _deposit = deposits[depositNumber];
        require(block.timestamp > _deposit.unlockBlock, Errors.ONLY_AFTER_END_BLOCK);

        stakedTokensToWithdraw = (fraction * _deposit.amount) / weightScale;
        stakedTokensToBeAddedBack = _deposit.amount - stakedTokensToWithdraw;

        require(stakedTokensToWithdraw != 0, Errors.SHOULD_BE_NON_ZERO);

        (plasmToClaim, vestedRewardsObtained) = _calculateParamWhenWithdrawUfo(_deposit, depositNumber, totalPoolShare);

        tvl = tvl - stakedTokensToWithdraw;

        emit Withdraw(depositNumber);
    }

    /**
     * @notice internal function to withdraw multple deposits/UFO tokens
     * @param depositNumber Deposit Number to withdraw
     * @param depositor Address of the depositor
     */
    function _withdrawUfoMultiple(
        uint256 depositNumber,
        address depositor,
        uint256 totalPoolShare
    )
        internal
        onlyWhenDeposited(depositNumber)
        onlyDepositor(depositNumber, depositor)
        returns (
            uint256 plasmToClaim,
            uint256 stakedTokensToWithdraw,
            uint256 vestedTokensObtained
        )
    {
        Deposit storage _deposit = deposits[depositNumber];
        require(block.timestamp > _deposit.unlockBlock, Errors.ONLY_AFTER_END_BLOCK);

        (plasmToClaim, vestedTokensObtained) = _calculateParamWhenWithdrawUfo(_deposit, depositNumber, totalPoolShare);
        stakedTokensToWithdraw = _deposit.amount;
        tvl = tvl - _deposit.amount;

        emit Withdraw(depositNumber);
    }

    function _calculateParamWhenWithdrawUfo(
        Deposit storage _deposit,
        uint256 depositNumber,
        uint256 totalPoolShare
    ) internal returns (uint256 plasmToClaim, uint256 vestedReward) {
        (uint256 claimablePlasma, address user) = getClaimablePlasma(depositNumber);
        plasmToClaim = _claimPlasma(depositNumber, user, claimablePlasma);

        uint256 blockNumber = _getCurrentBlockWrtEndBlock();

        _deposit.plasmaLastClaimedAt = blockNumber;
        _deposit.depositState = DepositState.WITHDRAWN;
        _deposit.vestedRewardUnlockBlock = blockNumber + (vestingLockBlocks);

        uint256 numberOfBlocksStaked = block.timestamp - _deposit.startBlock;

        vestedReward = getVestedRewards(totalPoolShare, _deposit.amount, numberOfBlocksStaked);
        _deposit.vestedRewards = vestedReward;
    }

    /**
     * @notice Returns the number of Vested UFO token for a given deposit
     * @param depositNumber Deposit Number
     */
    function getUfoVestedAmount(uint256 depositNumber) external view returns (uint256) {
        Deposit storage _deposit = deposits[depositNumber];
        if (_deposit.depositState != DepositState.WITHDRAWN) {
            return 0;
        }

        uint256 numberOfBlocksStaked = block.timestamp - _deposit.startBlock;
        uint256 totalPoolShare = IStakingFactory(factory).getPoolShare(address(this));
        return getVestedRewards(totalPoolShare, _deposit.amount, numberOfBlocksStaked);
    }

    /**
     * @notice Withdraw Multiple Vested Rewards
     * @param depositNumbers Deposit Numbers to withdraw
     */
    function withdrawVestedUfoMultiple(uint256[] calldata depositNumbers) external {
        require(depositNumbers.length <= MAX_LOOP_ITERATIONS, Errors.EXCEEDS_MAX_ITERATION);
        _updatePlasmaPerBlockPerToken();
        uint256 totalAmount;
        for (uint256 index = 0; index < depositNumbers.length; index++) {
            totalAmount += _withdrawVestedUfoMultiple(depositNumbers[index], msg.sender);
        }
        _transferVestedRewards(msg.sender, totalAmount);
    }

    /**
     * @notice Internal function to withdraw UFO tokens
     * @param depositNumber Deposit to claim the vested reward
     * @param depositor of the depositor
     */
    function _withdrawVestedUfoMultiple(uint256 depositNumber, address depositor)
        internal
        onlyWhenWithdrawn(depositNumber)
        onlyDepositor(depositNumber, depositor)
        returns (uint256)
    {
        Deposit storage _deposit = deposits[depositNumber];
        require(block.timestamp > _deposit.vestedRewardUnlockBlock, Errors.VESTED_TIME_NOT_REACHED);
        _deposit.depositState = DepositState.REWARD_CLAIMED;
        emit WithdrawVestedReward(depositNumber);
        return _deposit.vestedRewards;
    }

    /**
     * @notice Returns the number of  plasma claimed
     * @param depositNumber Deposit Number
     */
    function getClaimablePlasma(uint256 depositNumber) public view returns (uint256 claimablePlasma, address user) {
        Deposit storage _deposit = deposits[depositNumber];
        user = _deposit.user;
        if (_deposit.depositState != DepositState.DEPOSITED) {
            claimablePlasma = 0;
        } else {
            uint256 blockNumber = _getCurrentBlockWrtEndBlock();
            claimablePlasma =
                ((blockNumber - (_deposit.plasmaLastClaimedAt)) * (plasmaPerBlockPerToken) * (_deposit.amount)) /
                (weightScale);
        }
    }

    /**
     * @notice Returns the number of Vested Rewards for given number of blocks and amount
     * @param totalPoolShare Total share of the pool
     * @param amount Amount of staked token
     * @param numberOfBlocksStaked Number of blocks staked
     */
    function getVestedRewards(
        uint256 totalPoolShare,
        uint256 amount,
        uint256 numberOfBlocksStaked
    ) internal view returns (uint256) {
        return (totalPoolShare * (amount) * (numberOfBlocksStaked)) / (totalBlocksPerYear) / (tvl);
    }

    /**
     * @notice Internal function to claim plasma tokens. The claimed plasma tokens are sent to polygon chain directly
     * @param user Address to transfer
     * @param amount Amount of tokens to transfer
     */
    function _claimPlasma(
        uint256 depositNumber,
        address user,
        uint256 amount
    ) internal returns (uint256) {
        require(amount != 0, Errors.SHOULD_BE_NON_ZERO);
        emit ClaimPlasma(depositNumber, user, amount);
        return amount;
    }

    // if recipient is address(0), send to depositor eth address, else bridge it on polygon
    function _mintAndSendPlasma(
        address depositor,
        uint256 amount,
        address recipient
    ) internal {
        if (recipient != address(0)) {
            uint256 amountMinted = IERC20Mintable(plasmaToken).mint(address(this), amount);
            bool status = IERC20Upgradeable(plasmaToken).approve(erc20Predicate, amountMinted); // use of safeApprove is depricated and not recommended
            require(status, Errors.APPROVAL_UNSUCCESSFUL);
            IRootChainManager(maticBridge).depositFor(recipient, plasmaToken, abi.encode(amountMinted));
        } else {
            IERC20Mintable(plasmaToken).mint(depositor, amount);
        }
        IStakingFactory(factory).updateClaimedPlasma(amount);
    }

    /**
     * @notice Function to transfer vested rewards to the receiver
     * @param receiver Address that recevies the tokens
     * @param amount Amount of tokens to send
     */
    function _transferVestedRewards(address receiver, uint256 amount) internal {
        IStakingFactory(factory).flushReward(receiver, amount);
    }

    /**
     * @notice Withdraw Multiple Vested Rewards
     * @param depositNumbers Deposit Numbers to emergency withdraw
     */
    function emergencyWithdrawMultiple(uint256[] calldata depositNumbers) external {
        require(depositNumbers.length <= MAX_LOOP_ITERATIONS, Errors.EXCEEDS_MAX_ITERATION);
        uint256 totalAmount;
        for (uint256 index = 0; index < depositNumbers.length; index++) {
            totalAmount = totalAmount + _emergencyWithdrawMultiple(depositNumbers[index], msg.sender);
        }

        if (tvl < totalAmount) {
            totalAmount = tvl;
        }

        tvl = tvl - totalAmount;

        IERC20Upgradeable(stakingToken).safeTransfer(msg.sender, totalAmount);
        try IStakingFactory(factory).updateTVL(tvl) {} catch Error(string memory) {}
    }

    /**
     * @notice Internal function to withdraw the tokens
     * @param depositNumber Deposit number
     * @param depositor Address of the depositor
     */
    function _emergencyWithdrawMultiple(uint256 depositNumber, address depositor)
        internal
        onlyWhenDeposited(depositNumber)
        onlyDepositor(depositNumber, depositor)
        whenPaused
        returns (uint256)
    {
        Deposit memory _deposit = deposits[depositNumber];
        delete deposits[depositNumber];
        emit EmegencyWithdrawToken(depositNumber);
        return _deposit.amount;
    }

    /**
     * @notice Return the staking end block
     */
    function _getCurrentBlockWrtEndBlock() internal view returns (uint256 blockNumber) {
        blockNumber = block.timestamp;
    }

    /**
     * @notice function to pause
     */
    function pauseStaking() external onlyOwner {
        _pause();
    }

    /**
     * @notice function to unpause
     */
    function unpauseStaking() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Update Plasma Tokens Per Block
     */
    function _updatePlasmaPerBlockPerToken() internal {
        uint256 _plasmaPerBlockPerToken = IStakingFactory(factory).getPlasmaPerBlock();
        plasmaPerBlockPerToken = _plasmaPerBlockPerToken / totalBlocksPerYear;
        emit UpdatePlasmaPerBlockPerToken(plasmaPerBlockPerToken);
    }

    /**
     * @notice Update the plasma per block in the current pool
     */
    function upatePlasmPerBlock() external {
        _updatePlasmaPerBlockPerToken();
    }

    /**
     * @notice Modifier that allows only factory contract to call
     */
    modifier onlyFactory() {
        require(msg.sender == factory, Errors.ONLY_FACTORY_CAN_CALL);
        _;
    }

    /**
     * @notice Modifier to check if the deposit state is DEPOSITED
     */
    modifier onlyWhenDeposited(uint256 depositNumber) {
        require(deposits[depositNumber].depositState == DepositState.DEPOSITED, Errors.ONLY_WHEN_DEPOSITED);
        _;
    }

    /**
     * @notice Modifier to check if the deposit state is WITHDRAWN
     */
    modifier onlyWhenWithdrawn(uint256 depositNumber) {
        require(deposits[depositNumber].depositState == DepositState.WITHDRAWN, Errors.ONLY_WHEN_WITHDRAWN);
        _;
    }

    /**
     * @notice Modifier to ensure only depositor calls
     */
    modifier onlyDepositor(uint256 depositNumber, address depositor) {
        require(deposits[depositNumber].user == depositor, Errors.ONLY_DEPOSITOR);
        _;
    }
}
