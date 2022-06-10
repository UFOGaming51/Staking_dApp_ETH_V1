//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './Errors.sol';

import './interfaces/IStaking.sol';
import './interfaces/IStakingFactory.sol';
import '@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol';
import 'hardhat/console.sol';

contract StakingFactory is Ownable, IStakingFactory {
    using SafeERC20 for IERC20;

    struct Pool {
        uint256 tvl;
        uint256 weight;
        bool isPool;
        bool ufoPool;
    }

    /**
     * @notice Total Weight of UFO tokens
     */
    uint256 public totalUfoWeight;

    /**
     * @notice Total UFO tokens locked in all pools
     */
    uint256 public totalUfoLocked;

    /**
     * @notice Total Lp tokens locked in all pools
     */
    uint256 public totalLpLocked;

    /**
     * @notice Total Weight of LP tokens
     */
    uint256 public totalLpWeight;

    /**
     * @notice Weight is scaled by 1e18
     */
    uint256 public constant WEIGHT_SCALE = 1e18;

    /**
     * @notice event when pool is created
     * @param poolIndex Index of the pool
     * @param pool address of the pool
     */
    event CreatePool(uint256 indexed poolIndex, address indexed pool);

    /**
     * @notice event when tvl is updated
     * @param pool address of the pool
     */
    event UpdateTvl(address indexed pool, uint256 tvl);

    /**
     * @notice pool params
     */
    mapping(address => Pool) public pools;

    /**
     * @notice pool number to pool address
     */
    mapping(uint256 => address) public poolNumberToPoolAddress;

    /**
     * @notice total number of pools
     */
    uint256 public constant totalPools = 54;

    /**
     * @notice total ufo token rewards allocation for locked pools
     */
    uint256 public ufoRewardsForUfoPools;

    /**
     * @notice total ufo token rewards allocation for unlocked pools
     */
    uint256 public ufoRewardsForLpPools;

    /**
     * @notice total ufo token claimed from the ufo pools
     */
    uint256 public claimedUfoRewardsForUfoPools;

    /**
     * @notice total ufo token rewards claimed from the lp pools
     */
    uint256 public claimedUfoRewardsForLpPools;

    /**
     * @notice Total Plasma Rewards Allocated for UFO Pools
     */
    uint256 public plasmaRewardsForUfoPools;

    /**
     * @notice Total Plasma Rewards for Lp Pools
     */
    uint256 public plasmaRewardsForLpPools;

    /**
     * @notice Plasma Rewards claimed for UFO pools
     */
    uint256 public claimedPlasmaRewardsForUfoPools;

    /**
     * @notice Plasma Rewards claimed for LP pools
     */
    uint256 public claimedPlasmaRewardsForLpPools;

    /**
     * @notice address of the reward token
     */
    address public immutable rewardToken;

    /**
     * @notice Constructor
     * @param _beacon address of the beacon contract
     * @param _admin Address of the admin
     * @param _ufoRewardsForUfoPoolsPools Ufo Rewards to be distributed for the locked pools
     * @param _ufoRewardsForLpPoolsPools Ufo Rewards to be distributed for the unlocked pools
     * @param _rewardToken Address of the reward token,
     * @param _ufoToken Address of the ufo token
     * @param _lpToken Address of the lp token
     */
    constructor(
        address _beacon,
        address _admin,
        uint256 _ufoRewardsForUfoPoolsPools,
        uint256 _ufoRewardsForLpPoolsPools,
        address _rewardToken,
        address _ufoToken,
        address _lpToken
    ) {
        Ownable.transferOwnership(_admin);
        ufoRewardsForUfoPools = _ufoRewardsForUfoPoolsPools;
        ufoRewardsForLpPools = _ufoRewardsForLpPoolsPools;

        rewardToken = _rewardToken;

        uint256 totalTimeStampsPerYear = 365 * 24 * 60 * 60; // one year for second
        // uint256 totalTimeStampsPerYear = 1200; // for local
        // uint256 totalTimeStampsPerYear = 120000; // for goerli

        uint256 timeStampsPerWeek = totalTimeStampsPerYear / 52; //timestamps per week (1 year is 52 weeks)

        for (uint256 index = 0; index < totalPools; index += 2) {
            // for ease even pools are ufo pool, odd pools are lp pools
            uint256 lockInBlocks = timeStampsPerWeek * index + 1;
            _createUfoAndLpPools(_beacon, index, index + 1, _lpToken, _ufoToken, _admin, lockInBlocks, 1e18 + (index * 19230769230769230));
        }
    }

    function _createUfoAndLpPools(
        address _beacon,
        uint256 ufoPoolIndex,
        uint256 lpPoolIndex,
        address _lpToken,
        address _ufoToken,
        address _admin,
        uint256 lockInBlocks,
        uint256 weight
    ) internal {
        _createPool(_beacon, ufoPoolIndex, _ufoToken, lockInBlocks, _admin, weight);
        _createPool(_beacon, lpPoolIndex, _lpToken, lockInBlocks, _admin, weight);
    }

    /**
     * @notice internal function called in the constructor
     * @param poolIndex Index number of the pool
     * @param _stakingToken Address of the token to be staked
     * @param lockinBlocks Number of blocks the deposit is locked
     * @param _poolWeight Reward weight of the pool. Higher weight, higher rewards
     */
    function _createPool(
        address _beacon,
        uint256 poolIndex,
        address _stakingToken,
        uint256 lockinBlocks,
        address _admin,
        uint256 _poolWeight
    ) internal {
        require(_poolWeight != 0, Errors.SHOULD_BE_NON_ZERO);
        require(lockinBlocks != 0, Errors.SHOULD_BE_NON_ZERO);

        bytes memory empty;
        address _pool = address(new BeaconProxy(_beacon, empty));
        IStaking(_pool).initialize(_stakingToken, lockinBlocks, _admin, poolIndex == 0 || poolIndex == 1);
        pools[_pool] = Pool(0, _poolWeight, true, poolIndex % 2 == 0);
        poolNumberToPoolAddress[poolIndex] = _pool;
        emit CreatePool(poolIndex, _pool);
    }

    /**
     * @notice Update the TVL. Only a pool can call
     * @param tvl New TVL of the pool
     */
    function updateTVL(uint256 tvl) external override onlyPool {
        Pool storage pool = pools[msg.sender];
        if (pool.ufoPool) {
            totalUfoWeight = totalUfoWeight - ((pool.tvl * (pool.weight)) / (WEIGHT_SCALE)) + ((tvl * (pool.weight)) / (WEIGHT_SCALE));
            totalUfoLocked = totalUfoLocked - pool.tvl + tvl;
        } else {
            totalLpWeight = totalLpWeight - ((pool.tvl * (pool.weight)) / (WEIGHT_SCALE)) + ((tvl * (pool.weight)) / (WEIGHT_SCALE));
            totalLpLocked = totalLpLocked - pool.tvl + tvl;
        }
        pool.tvl = tvl;
        emit UpdateTvl(msg.sender, tvl);
    }

    /**
     * @notice Update Claimed Vested Rewards
     */
    function updateClaimedRewards(uint256 amount) external override onlyPool {
        if (pools[msg.sender].ufoPool) {
            claimedUfoRewardsForUfoPools += (amount);
        } else {
            claimedUfoRewardsForLpPools += (amount);
        }
    }

    function updateClaimedPlasma(uint256 amount) external override onlyPool {
        if (pools[msg.sender].ufoPool) {
            claimedPlasmaRewardsForUfoPools += amount;
        } else {
            claimedPlasmaRewardsForLpPools += amount;
        }
    }

    /**
     * @notice Send ufo token rewards user. Only a pool can call
     * @param user Address of the user to send reward to
     * @param amount Amount of tokens to send
     */
    function flushReward(address user, uint256 amount) external override onlyPool {
        IERC20(rewardToken).safeTransfer(user, amount);
    }

    /**
     * @notice Get Total Weight of TVL locked in all contracts
     */
    function getTotalTVLWeight() public view override returns (uint256 ufoPoolWeight, uint256 lpPoolWeight) {
        ufoPoolWeight = totalUfoWeight;
        lpPoolWeight = totalLpWeight;
    }

    /**
     * @notice Read the TVL
     */
    function getTotalTVL() public view override returns (uint256) {
        Pool memory _pool = pools[msg.sender];
        if (!_pool.isPool) {
            return 0;
        }

        if (_pool.ufoPool) {
            return totalUfoLocked;
        } else {
            return totalLpLocked;
        }
    }

    /**
     * @notice Returns plasma for pool multiplied by WEIGHT_SCALE
     */
    function getPlasmaPerBlock() external view override returns (uint256) {
        Pool memory _pool = pools[msg.sender];
        if (!_pool.isPool) {
            return 0;
        }
        if (_pool.ufoPool) {
            if (totalUfoWeight == 0) {
                // to avoid division overflow when tvl is 0
                return 0;
            }
            // console.log("plasmaRewardsForUfoPools",plasmaRewardsForUfoPools);
            // console.log("claimedPlasmaRewardsForUfoPools", claimedPlasmaRewardsForUfoPools);
            // console.log("totalUfoWeight", totalUfoWeight);
            return (((plasmaRewardsForUfoPools - claimedPlasmaRewardsForUfoPools) * _pool.weight) * WEIGHT_SCALE) / totalUfoWeight;
        } else {
            if (totalLpWeight == 0) {
                // to avoid division overflow when tvl is 0
                return 0;
            }
            // console.log("plasmaRewardsForLpPools", plasmaRewardsForLpPools);
            // console.log("claimedPlasmaRewardsForLpPools", claimedPlasmaRewardsForLpPools);
            // console.log("totalLpWeight", totalLpWeight);
            return (((plasmaRewardsForLpPools - claimedPlasmaRewardsForLpPools) * _pool.weight) * WEIGHT_SCALE) / totalLpWeight;
        }
    }

    /**
     * @notice Calculate the number of UFO reward tokens a pool is entitiled to at given point in time.
     * @param pool Address of the pool
     */
    function getPoolShare(address pool) public view override returns (uint256 amount) {
        Pool memory _pool = pools[pool];
        if (!_pool.isPool) {
            return 0;
        }
        (uint256 ufoPoolWeight, uint256 lpPoolWeight) = getTotalTVLWeight();

        uint256 totalTvlWeight = _pool.ufoPool ? ufoPoolWeight : lpPoolWeight;
        if (totalTvlWeight == 0) {
            // to avoid division overflow when tvl is 0
            return 0;
        }
        uint256 totalReward = _pool.ufoPool ? ufoRewardsForUfoPools : ufoRewardsForLpPools;

        uint256 claimedRewards = _pool.ufoPool ? claimedUfoRewardsForUfoPools : claimedUfoRewardsForLpPools;
        if (totalReward < claimedRewards) {
            amount = 0;
        } else {
            amount = ((totalReward - (claimedRewards)) * ((_pool.tvl * (_pool.weight)) / (WEIGHT_SCALE))) / (totalTvlWeight);
        }
    }

    /**
     * @notice Fetch Pool APR. Will return 0 if address is not a valid pool (or) the tvl in pool is zero
     * @param pool Address of the pool to fetch APR
     */
    function getPoolApr(address pool) public view returns (uint256) {
        uint256 share = getPoolShare(pool);
        Pool storage _pool = pools[pool];
        if (_pool.tvl == 0) {
            return 0;
        }
        return (share * (WEIGHT_SCALE)) / (_pool.tvl);
    }

    /**
     * @notice Change Ufo Rewards to be distributed for UFO pools
     * @param amount New Amount
     */
    function changeUfoRewardsForUfoPools(uint256 amount) external onlyOwner {
        require(amount > claimedUfoRewardsForUfoPools, Errors.SHOULD_BE_MORE_THAN_CLAIMED);
        ufoRewardsForUfoPools = amount;
    }

    /**
     * @notice Change Ufo Rewards to be distributed for LP pools
     * @param amount New Amount
     */
    function changeUfoRewardsForLpPools(uint256 amount) external onlyOwner {
        require(amount > claimedUfoRewardsForLpPools, Errors.SHOULD_BE_MORE_THAN_CLAIMED);
        ufoRewardsForLpPools = amount;
    }

    /**
     * @notice Withdraw UFO tokens available in case of any emergency
     * @param recipient Address to receive the emergency deposit
     */
    function emergencyWithdrawRewardBalance(address recipient) external onlyOwner {
        uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).safeTransfer(recipient, rewardBalance);
    }

    /**
     * @notice claim plasma from multiple pools
     * @param poolIndexes Pool Indexed to claim from
     * @param depositNumbers Deposit Numbers to claim
     */
    function claimPlasmaFromPools(
        uint256[] calldata poolIndexes,
        uint256[][] calldata depositNumbers,
        address plasmaRecipient
    ) external {
        require(poolIndexes.length == depositNumbers.length, Errors.ARITY_MISMATCH);
        for (uint256 index = 0; index < poolIndexes.length; index++) {
            claimPlasmaFromPool(poolIndexes[index], depositNumbers[index], plasmaRecipient);
        }
    }

    /**
     * @notice Change the reward rate of UFO pools
     * @param newValue new plasma reward
     */
    function changeUfoPoolPlasmaRewards(uint256 newValue) external onlyOwner {
        require(newValue > claimedPlasmaRewardsForUfoPools, Errors.SHOULD_BE_MORE_THAN_CLAIMED);
        plasmaRewardsForUfoPools = newValue;
    }

    /**
     * @notice Change the reward rate of LP pools
     * @param newValue new plasma reward
     */
    function changeLpPoolPlasmaRewards(uint256 newValue) external onlyOwner {
        require(newValue > claimedPlasmaRewardsForLpPools, Errors.SHOULD_BE_MORE_THAN_CLAIMED);
        plasmaRewardsForLpPools = newValue;
    }

    /**
     * @notice claim plasma from multiple pools
     * @param poolIndex Pool Index
     * @param depositNumbers Deposit Numbers to claim
     */
    function claimPlasmaFromPool(
        uint256 poolIndex,
        uint256[] calldata depositNumbers,
        address plasmaRecipient
    ) public {
        address pool = poolNumberToPoolAddress[poolIndex];
        require(pool != address(0), Errors.SHOULD_BE_NON_ZERO);
        IStaking(pool).claimPlasmaFromFactory(depositNumbers, msg.sender, plasmaRecipient);
    }

    /**
     * @notice ensures that sender is a registered pool
     */
    modifier onlyPool() {
        require(pools[msg.sender].isPool, Errors.ONLY_POOLS_CAN_CALL);
        _;
    }
}
