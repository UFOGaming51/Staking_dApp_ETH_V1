//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import './test.sol';
import './User.sol';

import '../ethereum/StakingFactory.sol';
import '../ethereum/Beacon.sol';
import '../ethereum/Staking.sol';
import '../ethereum/Plasma.sol';
import '../XToken.sol';
import './Hevm.sol';
import 'hardhat/console.sol';

contract StakingTest is DSTest {
    StakingFactory stakingFactory;
    Beacon beacon;
    Staking stakingImplementation;
    Plasma plasma;
    XToken ufotoken;
    XToken lptoken;

    User admin;
    User user1;
    User user2;

    uint256 public constant maxNumberOfUsers = 750;
    uint256 public constant minNumberOfUsers = 200;

    mapping(uint256 => User) public users;

    uint256 public constant maxUfoEachUserGets = 10000000000 * 10**18;
    uint256 public constant minUfoEachUserGets = 10**18;

    uint256 public constant maxLpEachUserGets = 1 * 10**16;
    uint256 public constant minLpEachUserGets = 10**12;

    address public constant ercPredicate = 0xdD6596F2029e6233DEFfaCa316e6A95217d4Dc34;
    address public constant maticBridge = 0xBbD7cBFA79faee899Eaf900F13C9065bF03B1A74;

    uint256 public constant ufoVestedRewardsForUfo = 321969696969 * 10**18;
    uint256 public constant ufoVestedRewardsForLp = 965909090909 * 10**18;

    uint256 public constant totalPlasmaRewards = 29500000 * 10**18;
    uint256 public constant plasmaRewardsForUfoPools = totalPlasmaRewards / 4;
    uint256 public constant plasmaRewardsForLpPools = (totalPlasmaRewards * 3) / 4;

    Hevm hemv = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    Staking[] public pools; // this temp and to be used in tests
    uint256[] public depositNumbersTemp; // this is temp and to be use in tests

    function setUp() public {
        admin = new User();
        user1 = new User();
        user2 = new User();

        ufotoken = new XToken('UFO Token', 'UFO', type(uint256).max, address(admin));
        lptoken = new XToken('LP Token', 'ETH-LP', type(uint256).max, address(admin));

        plasma = new Plasma('Plasma', 'PSM', address(admin));
        stakingImplementation = new Staking(address(plasma), ercPredicate, maticBridge);

        beacon = new Beacon(address(admin), address(stakingImplementation));
        stakingFactory = new StakingFactory(
            address(beacon),
            address(admin),
            ufoVestedRewardsForUfo,
            ufoVestedRewardsForLp,
            address(ufotoken),
            address(ufotoken),
            address(lptoken)
        );

        for (uint256 index = 0; index < maxNumberOfUsers; index++) {
            users[index] = new User();
        }

        admin.transferToken(address(ufotoken), address(stakingFactory), ufoVestedRewardsForUfo + ufoVestedRewardsForLp);

        for (uint256 index = 0; index < stakingFactory.totalPools(); index++) {
            admin.addMinterToPlasma(plasma, stakingFactory.poolNumberToPoolAddress(index));
        }

        admin.changeUfoPoolPlasmaPerBlock(stakingFactory, plasmaRewardsForUfoPools);
        admin.changeLpPoolPlasmaPerBlock(stakingFactory, plasmaRewardsForLpPools);
    }

    function test_sample(uint256 ufoAmount, uint256 lpAmount) public {
        ufoAmount = minUfoEachUserGets + (ufoAmount % (maxUfoEachUserGets - minUfoEachUserGets));
        lpAmount = minLpEachUserGets + (lpAmount % (maxLpEachUserGets - minLpEachUserGets));

        admin.transferToken(address(ufotoken), address(user1), ufoAmount);
        admin.transferToken(address(ufotoken), address(user2), ufoAmount);

        admin.transferToken(address(lptoken), address(user1), lpAmount);
        admin.transferToken(address(lptoken), address(user2), lpAmount);
    }

    function test_deposit_to_random_pool(
        uint256 randomizer,
        uint256 ufoAmount,
        uint256 lpAmount
    ) public {
        _deposit(randomizer, ufoAmount, lpAmount, user1);
    }

    function test_multiple_deposits(uint256 randomizer) public {
        uint256 totalNumberOfUserToUser = minNumberOfUsers + (randomizer % (maxNumberOfUsers - minNumberOfUsers));
        if (totalNumberOfUserToUser == 0) return;

        for (uint256 index = 0; index < totalNumberOfUserToUser; index++) {
            uint256 localRandomizer = abi.decode(abi.encode(randomizer, index), (uint256));
            _deposit(localRandomizer, localRandomizer, localRandomizer, users[index]);
        }
    }

    function test_claim_plasma(
        uint256 randomizer,
        uint256 ufoAmount,
        uint256 lpAmount
    ) public {
        require(pools.length == 0, 'Should be empty');
        require(depositNumbersTemp.length == 0, 'Should be empty');
        _claimPlasma(randomizer, ufoAmount, lpAmount, user2);
    }

    function test_plasmaForMultipleUser(uint256 randomizer) public {
        require(pools.length == 0, 'Should be empty');
        require(depositNumbersTemp.length == 0, 'Should be empty');
        uint256 totalNumberOfUserToUser = minNumberOfUsers + (randomizer % (maxNumberOfUsers - minNumberOfUsers));
        if (totalNumberOfUserToUser == 0) return;

        uint256 unlockBlock;
        for (uint256 index = 0; index < totalNumberOfUserToUser; index++) {
            uint256 localRandomizer = abi.decode(abi.encode(randomizer, index), (uint256));
            (uint256 blockNumber, Staking pool, uint256 depositNumber) = _deposit(
                localRandomizer,
                localRandomizer,
                localRandomizer,
                users[index]
            );
            pools.push(pool);
            depositNumbersTemp.push(depositNumber);
            if (unlockBlock < blockNumber) {
                unlockBlock = blockNumber;
            }
        }

        hemv.warp(unlockBlock + 1); // after all deposits unlocked
        for (uint256 index = 0; index < totalNumberOfUserToUser; index++) {
            uint256[] memory depositNumbers = new uint256[](1);
            depositNumbers[0] = depositNumbersTemp[index];
            _claimPlasmaInternal(pools[index], depositNumbers, users[index]);
        }
        assertLt(plasma.totalSupply(), totalPlasmaRewards);
        // assertLt(plasma.totalSupply(), 1);
    }

    function test_vestedRewardsClaim(uint256 randomizer) public {
        require(pools.length == 0, 'Should be empty');
        require(depositNumbersTemp.length == 0, 'Should be empty');
        uint256 totalNumberOfUserToUser = minNumberOfUsers + (randomizer % (maxNumberOfUsers - minNumberOfUsers));
        if (totalNumberOfUserToUser == 0) return;

        uint256 unlockBlock;
        for (uint256 index = 0; index < totalNumberOfUserToUser; index++) {
            uint256 localRandomizer = abi.decode(abi.encode(randomizer, index), (uint256));
            (uint256 blockNumber, Staking pool, uint256 depositNumber) = _deposit(
                localRandomizer,
                localRandomizer,
                localRandomizer,
                users[index]
            );
            pools.push(pool);
            depositNumbersTemp.push(depositNumber);
            if (unlockBlock < blockNumber) {
                unlockBlock = blockNumber;
            }
        }

        hemv.warp(unlockBlock + 1); // after all deposits unlocked

        uint256 vestedBlock;
        for (uint256 index = 0; index < totalNumberOfUserToUser; index++) {
            uint256[] memory depositNumbers = new uint256[](1);
            depositNumbers[0] = depositNumbersTemp[index];
            uint256 blockNumber = _claimPlasmaInternal(pools[index], depositNumbers, users[index]);
            if (vestedBlock < blockNumber) {
                vestedBlock = blockNumber;
            }
        }

        hemv.warp(vestedBlock + 1); // after all vested rewards time is reached
        for (uint256 index = 0; index < totalNumberOfUserToUser; index++) {
            uint256[] memory depositNumbers = new uint256[](1);
            depositNumbers[0] = depositNumbersTemp[index];
            uint256 vestedRewardAvailable = IERC20(address(ufotoken)).balanceOf(address(stakingFactory));
            (, , , , , , , uint256 vestedRewards) = pools[index].deposits(depositNumbers[0]);
            if (vestedRewards > vestedRewardAvailable) {
                emit log_named_uint('vested reward failed for nth user', index);
                emit log_named_uint('total number of users used in the test', totalNumberOfUserToUser);
                emit log_named_uint('vestedRewards needed for user', vestedRewards);
                emit log_named_uint('vestedRewardAvailable', vestedRewardAvailable);
            }
            assertLt(vestedRewards, vestedRewardAvailable + 1); // +1 for greater than or equal to
            users[index].claimVestedReward(pools[index], depositNumbers);
        }
    }

    function invariant_totalSupply() public {
        assertLt(plasma.totalSupply(), totalPlasmaRewards);
    }

    function _claimPlasmaInternal(
        Staking staking,
        uint256[] memory depositNumbers,
        User userToUse
    ) internal returns (uint256 vestedUnlockBlock) {
        userToUse.unstake(staking, depositNumbers, address(0));
        for (uint256 index = 0; index < depositNumbers.length; index++) {
            (, , , , , , uint256 blockNumber, ) = staking.deposits(depositNumbers[index]); // this is timestamp;
            if (vestedUnlockBlock < blockNumber) {
                vestedUnlockBlock = blockNumber;
            }
        }
    }

    function _claimPlasma(
        uint256 randomizer,
        uint256 ufoAmount,
        uint256 lpAmount,
        User userToUse
    ) internal {
        ufoAmount = minUfoEachUserGets + (ufoAmount % (maxUfoEachUserGets - minUfoEachUserGets));
        lpAmount = minLpEachUserGets + (lpAmount % (maxLpEachUserGets - minLpEachUserGets));

        admin.transferToken(address(ufotoken), address(userToUse), ufoAmount);
        admin.transferToken(address(lptoken), address(userToUse), lpAmount);

        uint256 totalPools = stakingFactory.totalPools();
        uint256 poolNumber = randomizer % totalPools;
        Staking poolToUse = Staking(stakingFactory.poolNumberToPoolAddress(poolNumber));

        if (poolNumber % 2 == 0) {
            userToUse.approveToken(address(ufotoken), address(poolToUse), ufoAmount);
            userToUse.stake(poolToUse, ufoAmount);
        } else {
            userToUse.approveToken(address(lptoken), address(poolToUse), lpAmount);
            userToUse.stake(poolToUse, lpAmount);
        }

        (, , uint256 unlockBlock, , , , , ) = poolToUse.deposits(poolToUse.depositCounter()); // this is timestamp;
        // emit log_named_uint('unlockBlock', unlockBlock);

        hemv.warp(unlockBlock + 1);
        uint256[] memory depositNumbers = new uint256[](1);
        depositNumbers[0] = poolToUse.depositCounter();
        userToUse.unstake(poolToUse, depositNumbers, address(0));
    }

    function _deposit(
        uint256 randomizer,
        uint256 ufoAmount,
        uint256 lpAmount,
        User userToUse
    )
        internal
        returns (
            uint256 unlockBlock,
            Staking pool,
            uint256 depositNumber
        )
    {
        ufoAmount = minUfoEachUserGets + (ufoAmount % (maxUfoEachUserGets - minUfoEachUserGets));
        lpAmount = minLpEachUserGets + (lpAmount % (maxLpEachUserGets - minLpEachUserGets));

        admin.transferToken(address(ufotoken), address(userToUse), ufoAmount);
        admin.transferToken(address(lptoken), address(userToUse), lpAmount);

        uint256 totalPools = stakingFactory.totalPools();
        uint256 poolNumber = randomizer % totalPools;
        Staking poolToUse = Staking(stakingFactory.poolNumberToPoolAddress(poolNumber));
        if (poolNumber % 2 == 0) {
            userToUse.approveToken(address(ufotoken), address(poolToUse), ufoAmount);
            userToUse.stake(poolToUse, ufoAmount);
        } else {
            userToUse.approveToken(address(lptoken), address(poolToUse), lpAmount);
            userToUse.stake(poolToUse, lpAmount);
        }

        (, , unlockBlock, , , , , ) = poolToUse.deposits(poolToUse.depositCounter()); // this is timestamp;
        pool = poolToUse;
        depositNumber = poolToUse.depositCounter();
    }
}

// (uint256 amount,
// uint256 startBlock,
// uint256 unlockBlock,
// uint256 plasmaLastClaimedAt,
// address user,
// DepositState depositState,
// uint256 vestedRewardUnlockBlock,
// uint256 vestedRewards)
