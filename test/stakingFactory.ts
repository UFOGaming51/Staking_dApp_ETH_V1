import { ethers, network } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumber, BigNumberish } from '@ethersproject/bignumber';
import { expect } from 'chai';

import { XToken } from '../typechain/XToken';

import DeployHelper from '../utils/deployer';
import { StakingFactory } from '../typechain/StakingFactory';
import { MockRootChainManager } from '../typechain/MockRootChainManager';
import { Plasma } from '../typechain/Plasma';
import { Staking } from '../typechain/Staking';

import { Errors } from '../typechain/Errors';
import { Errors__factory } from '../typechain/factories/Errors__factory';
import { Network } from 'hardhat/types';
import { Beacon } from '../typechain/Beacon';
import { DepositHelper } from '../typechain/DepositHelper';
import { zeroAddress } from '../utils/constants';
import { expectApproxEqual } from '../utils/helper';

describe('Staking Factory', async () => {
    let stakingFactory: StakingFactory;
    let ufoToken: XToken;
    let lpToken: XToken;
    let plasmaToken: Plasma;
    let beacon: Beacon;
    let depositHelper: DepositHelper;

    let admin: SignerWithAddress;
    let proxyAdmin: SignerWithAddress;
    let otherAddress1: SignerWithAddress;
    let otherAddress2: SignerWithAddress;
    let otherAddress3: SignerWithAddress;
    let otherAddress4: SignerWithAddress;

    let maticBridge: MockRootChainManager;
    let errors: Errors;

    let snapshotId: any;

    before(async () => {
        [proxyAdmin, admin, otherAddress1, otherAddress2, otherAddress3, otherAddress4] = await ethers.getSigners();

        let deployHelper = new DeployHelper(admin);
        ufoToken = await deployHelper.helper.deployXToken('UFO Token', 'UFO', BigNumber.from(10).pow(18).mul('51000000000'), admin.address);
        lpToken = await deployHelper.helper.deployXToken('UFO-ETH-LP', 'LP', BigNumber.from(10).pow(18).mul(12).div(10), admin.address);
        plasmaToken = await deployHelper.eth.deployPlasma('Plasma', 'PLSM', admin.address);
        maticBridge = await deployHelper.helper.deployMockRootChainManager();
        let stakingImplemenation = await deployHelper.helper.deployStaking(plasmaToken.address, maticBridge.address, maticBridge.address);
        beacon = await deployHelper.helper.deployBeacon(admin.address, stakingImplemenation.address);
        stakingFactory = await deployHelper.helper.deployStakingFactory(
            beacon.address,
            admin.address,
            BigNumber.from(10).pow(18).mul(7500),
            BigNumber.from(10).pow(18).mul(2500),
            ufoToken.address,
            ufoToken.address,
            lpToken.address
        );

        let totalPools = await stakingFactory.totalPools();

        let allUfoPools: string[] = [];
        let allLpPools: string[] = [];
        for (let index = 0; index < totalPools.toNumber(); index++) {
            let poolAddress = await stakingFactory.poolNumberToPoolAddress(index);
            if (index == 0) {
                allUfoPools.push(poolAddress);
            } else {
                allLpPools.push(poolAddress);
            }
            await plasmaToken.connect(admin).addMinter(poolAddress);
        }

        depositHelper = await deployHelper.helper.deployDepositHelper(allUfoPools, allLpPools, ufoToken.address, lpToken.address);
        errors = await new Errors__factory(admin).deploy();
        await stakingFactory.connect(admin).changeUfoPoolPlasmaPerBlock(BigNumber.from(10).pow(18));
        await stakingFactory.connect(admin).changeLpPoolPlasmaPerBlock(BigNumber.from(10).pow(18).mul(3).div(2));
    });

    beforeEach(async () => {
        snapshotId = await network.provider.request({
            method: 'evm_snapshot',
            params: [],
        });
    });

    afterEach(async () => {
        await network.provider.request({
            method: 'evm_revert',
            params: [snapshotId],
        });
    });

    it('Check deployment', async () => {
        console.log({ stakingFactoryAddress: stakingFactory.address });
    });

    it('Check weights of pools', async () => {
        let totalPools = await (await stakingFactory.totalPools()).toNumber();
        let firstPoolAddress = await stakingFactory.connect(admin).poolNumberToPoolAddress(0);
        let lastPoolAddress = await stakingFactory.connect(admin).poolNumberToPoolAddress(totalPools - 1);

        let firstPoolWeight = await (await stakingFactory.connect(admin).pools(firstPoolAddress)).weight;
        let lastPoolWeight = await (await stakingFactory.connect(admin).pools(lastPoolAddress)).weight;

        expect(firstPoolWeight).eq('1000000000000000000');
        expectApproxEqual(lastPoolWeight, '2000000000000000000', 'deviation too high', BigNumber.from(100));
    });

    describe('Unlocked UFO Pool', async () => {
        let ufoPool: Staking;
        let amountToStake: BigNumber;
        beforeEach(async () => {
            let ufoPoolAddress = await stakingFactory.poolNumberToPoolAddress(0);
            let deployHelper = new DeployHelper(admin);
            ufoPool = await deployHelper.helper.getStaking(ufoPoolAddress);

            amountToStake = BigNumber.from(10).pow(20); // 100 UFO
            await ufoToken.connect(admin).transfer(otherAddress1.address, amountToStake); // 100 UFO
        });

        it('Ufo Pool Address', async () => {
            console.log({ ufoPool: ufoPool.address });
        });

        it('Should fail to claim plasma if no deposit', async () => {
            await expect(ufoPool.connect(otherAddress1).claimPlasmaMultiple([1], otherAddress1.address)).to.be.revertedWith(
                await errors.ONLY_WHEN_DEPOSITED()
            );
        });

        it('Should deposit', async () => {
            await (await ufoToken.connect(otherAddress1).approve(ufoPool.address, amountToStake)).wait();
            let currentBlock = await getCurrentBlock(network);
            let oldTvl = await ufoPool.tvl();
            let [oldUfoPoolTvl, oldLpPoolTvl] = await stakingFactory.getTotalTVLWeight();

            await expect(ufoPool.connect(otherAddress1).deposit(amountToStake))
                .to.emit(ufoPool, 'Deposited')
                .withArgs(1, otherAddress1.address, amountToStake, currentBlock + 2); // bit ambigious

            let newTvl = await ufoPool.tvl();
            expect(newTvl.sub(oldTvl)).eq(amountToStake);

            let [newUfoPoolTvl, newLpPoolTvl] = await stakingFactory.getTotalTVLWeight();

            // weight is 1 this pool, hence weight is ignored here
            expect(newUfoPoolTvl.sub(oldUfoPoolTvl)).eq(amountToStake);
            expect(newLpPoolTvl).eq(oldLpPoolTvl);

            // verify deposit state
            await expect(await ufoPool.depositCounter()).eq(1);
            let deposit = await ufoPool.deposits(1);

            expect(deposit.startBlock).eq(currentBlock + 1);
            expect(deposit.unlockBlock).eq(currentBlock + 2);
            expect(deposit.amount).eq(amountToStake);
            expect(deposit.user).eq(otherAddress1.address);
            expect(deposit.depositState).eq(1);
            expect(deposit.vestedRewardUnlockBlock).eq(0);
            expect(deposit.vestedRewards).eq(0);
        });

        it('should deposit using deposit helper', async () => {
            await ufoToken.connect(otherAddress1).approve(depositHelper.address, amountToStake);
            let currentBlock = await getCurrentBlock(network);
            await expect(depositHelper.connect(otherAddress1).depositUfoToPool(ufoPool.address, amountToStake))
                .to.emit(ufoPool, 'Deposited')
                .withArgs(1, otherAddress1.address, amountToStake, currentBlock + 2); // bit ambigious
        });

        it('emeregency withdraw', async () => {
            await ufoToken.connect(otherAddress1).approve(depositHelper.address, amountToStake);
            await depositHelper.connect(otherAddress1).depositUfoToPool(ufoPool.address, amountToStake);
            await ufoPool.connect(admin).pauseStaking();
            await expect(ufoPool.connect(otherAddress1).emergencyWithdrawMultiple([1]))
                .to.emit(ufoPool, 'EmegencyWithdrawToken')
                .withArgs(1);
        });

        it('emeregency withdraw should fail if contract is not paused', async () => {
            await ufoToken.connect(otherAddress1).approve(depositHelper.address, amountToStake);
            await depositHelper.connect(otherAddress1).depositUfoToPool(ufoPool.address, amountToStake);
            await expect(ufoPool.connect(otherAddress1).emergencyWithdrawMultiple([1])).to.be.revertedWith('Pausable: not paused');
        });

        it('Should claim plasma from pool factory', async () => {
            await (await ufoToken.connect(otherAddress1).approve(ufoPool.address, amountToStake)).wait();
            await ufoPool.connect(otherAddress1).deposit(amountToStake);

            let plasmaBalanceBefore = await plasmaToken.balanceOf(otherAddress1.address);
            await mineBlocks(network, 20);
            await stakingFactory.connect(otherAddress1).claimPlasmaFromPools([0], [[1]], otherAddress1.address);
            let plasmaBalanceAfter = await plasmaToken.balanceOf(otherAddress1.address);

            expect(plasmaBalanceAfter.sub(plasmaBalanceBefore)).not.eq(0);
            console.log({ received: plasmaBalanceAfter.sub(plasmaBalanceBefore).toString() });
        });

        it('Should fail if plasma is claimed from some other account', async () => {
            await (await ufoToken.connect(otherAddress1).approve(ufoPool.address, amountToStake)).wait();
            await ufoPool.connect(otherAddress1).deposit(amountToStake);

            await mineBlocks(network, 20);
            await expect(stakingFactory.connect(admin).claimPlasmaFromPools([0], [[1]], admin.address)).to.be.revertedWith(
                await errors.ONLY_DEPOSITOR()
            );
        });

        it('Should claimPlasma after 20 blocks', async () => {
            await (await ufoToken.connect(otherAddress1).approve(ufoPool.address, amountToStake)).wait();
            await ufoPool.connect(otherAddress1).deposit(amountToStake);

            let plasmaBalanceBefore = await plasmaToken.balanceOf(otherAddress1.address);
            await mineBlocks(network, 20);
            await ufoPool.connect(otherAddress1).claimPlasmaMultiple([1], otherAddress1.address);
            let plasmaBalanceAfter = await plasmaToken.balanceOf(otherAddress1.address);

            expect(plasmaBalanceAfter.sub(plasmaBalanceBefore)).not.eq(0);
            console.log({ received: plasmaBalanceAfter.sub(plasmaBalanceBefore).toString() });
        });

        it('Should withdraw deposit after 50 blocks (while remaining plasma should be also claimed)', async () => {
            await (await ufoToken.connect(otherAddress1).approve(ufoPool.address, amountToStake)).wait();
            let currentBlock = await getCurrentBlock(network);

            await ufoPool.connect(otherAddress1).deposit(amountToStake);

            let plasmaBalanceBefore = await plasmaToken.balanceOf(otherAddress1.address);
            await mineBlocks(network, 50);
            await ufoPool.connect(otherAddress1).withdrawUfoMultiple([1], otherAddress1.address);
            let plasmaBalanceAfter = await plasmaToken.balanceOf(otherAddress1.address);
            expect(plasmaBalanceAfter.sub(plasmaBalanceBefore)).not.eq(0);
            console.log({ received: plasmaBalanceAfter.sub(plasmaBalanceBefore).toString() });

            let deposit = await ufoPool.deposits(1);
            expect(deposit.depositState).eq(2);
            expect(deposit.unlockBlock).eq(currentBlock + 2);
            expect(deposit.vestedRewardUnlockBlock).eq(currentBlock + 2 + 50 + (await (await ufoPool.vestingLockBlocks()).toNumber()));
            console.log({ vestedReward: deposit.vestedRewards.toString() });
        });

        it('Should not be able to claim plasma after the staking ends', async () => {
            await (await ufoToken.connect(otherAddress1).approve(ufoPool.address, amountToStake)).wait();

            await ufoPool.connect(otherAddress1).deposit(amountToStake);

            let currentBlock = await getCurrentBlock(network);
            let stakingEndBlock = await ufoPool.stakingEndBlock();
            let blocksToMove = await stakingEndBlock.sub(currentBlock).toNumber();
            console.log({ blocksToMove });
            await mineBlocks(network, blocksToMove);

            await ufoPool.connect(otherAddress1).claimPlasmaMultiple([1], otherAddress1.address);
            await expect(ufoPool.connect(otherAddress1).claimPlasmaMultiple([1], otherAddress1.address)).to.be.revertedWith(
                await errors.SHOULD_BE_NON_ZERO()
            );
        });

        it('Should not able to withdraw twice', async () => {
            await (await ufoToken.connect(otherAddress1).approve(ufoPool.address, amountToStake)).wait();

            await ufoPool.connect(otherAddress1).deposit(amountToStake);

            await mineBlocks(network, 51);
            await ufoPool.connect(otherAddress1).withdrawUfoMultiple([1], otherAddress1.address);
            await expect(ufoPool.connect(otherAddress1).withdrawUfoMultiple([1], otherAddress1.address)).to.be.revertedWith(
                await errors.ONLY_WHEN_DEPOSITED()
            );
        });

        it('should be able to withdraw partial amount from flexi pool', async () => {
            await (await ufoToken.connect(otherAddress1).approve(ufoPool.address, amountToStake)).wait();

            await ufoPool.connect(otherAddress1).deposit(amountToStake);

            let totalDepositsBefore = await ufoPool.depositCounter();
            await mineBlocks(network, 51);

            let ufoBalanceBefore = await ufoToken.balanceOf(otherAddress1.address);
            await ufoPool.connect(otherAddress1).withdrawPartialUfoMultiple([1], BigNumber.from(10).pow(17), otherAddress1.address); // 10 % withdraw
            let ufoBalanceAfter = await ufoToken.balanceOf(otherAddress1.address);

            let totalDepositsAfter = await ufoPool.depositCounter();

            expect(totalDepositsAfter).eq(totalDepositsBefore.add(1));

            let balanceReceived = ufoBalanceAfter.sub(ufoBalanceBefore);
            expect(balanceReceived).eq(amountToStake.div(10));
        });

        it('should be able to partial withdraw amount from flexi pool using multiple withdraw', async () => {
            await (await ufoToken.connect(otherAddress1).approve(ufoPool.address, amountToStake)).wait();
            await ufoPool.connect(otherAddress1).deposit(amountToStake);

            await ufoToken.connect(admin).transfer(otherAddress1.address, amountToStake); // 100 UFO
            await (await ufoToken.connect(otherAddress1).approve(ufoPool.address, amountToStake)).wait();
            await ufoPool.connect(otherAddress1).deposit(amountToStake);

            let totalDepositsBefore = await ufoPool.depositCounter();
            await mineBlocks(network, 51);

            let ufoBalanceBefore = await ufoToken.balanceOf(otherAddress1.address);
            await ufoPool.connect(otherAddress1).withdrawPartialUfoMultiple([1, 2], BigNumber.from(10).pow(16), zeroAddress); // 1 % withdraw
            let ufoBalanceAfter = await ufoToken.balanceOf(otherAddress1.address);

            let totalDepositsAfter = await ufoPool.depositCounter();

            expect(totalDepositsAfter).eq(totalDepositsBefore.add(1));

            let balanceReceived = ufoBalanceAfter.sub(ufoBalanceBefore);
            expect(balanceReceived).eq(amountToStake.div(100).mul(2));
        });

        it('Only depositor should be able withdraw', async () => {
            await (await ufoToken.connect(otherAddress1).approve(ufoPool.address, amountToStake)).wait();

            await ufoPool.connect(otherAddress1).deposit(amountToStake);

            await mineBlocks(network, 50);
            await expect(ufoPool.connect(admin).withdrawUfoMultiple([1], zeroAddress)).to.be.revertedWith(await errors.ONLY_DEPOSITOR());
        });

        it('Claim vested rewards can;t be claimed before vesting end date', async () => {
            await (await ufoToken.connect(otherAddress1).approve(ufoPool.address, amountToStake)).wait();

            await ufoPool.connect(otherAddress1).deposit(amountToStake);

            await mineBlocks(network, 50);
            await ufoPool.connect(otherAddress1).withdrawUfoMultiple([1], zeroAddress);
            await expect(ufoPool.connect(otherAddress1).withdrawVestedUfoMultiple([1])).to.be.revertedWith(
                await errors.VESTED_TIME_NOT_REACHED()
            );
        });

        it('Claim vested rewards', async () => {
            await (await ufoToken.connect(otherAddress1).approve(ufoPool.address, amountToStake)).wait();

            await ufoPool.connect(otherAddress1).deposit(amountToStake);

            await mineBlocks(network, 50);
            await ufoPool.connect(otherAddress1).withdrawUfoMultiple([1], zeroAddress);
            let currentBlock = await getCurrentBlock(network);
            let vestedRewardUnlockBlock = await (await ufoPool.deposits(1)).vestedRewardUnlockBlock.toNumber();

            await mineBlocks(network, vestedRewardUnlockBlock - currentBlock + 1);
            await ufoToken.connect(admin).transfer(stakingFactory.address, await stakingFactory.ufoRewardsForUfoPools());
            await ufoToken.connect(admin).transfer(stakingFactory.address, await stakingFactory.ufoRewardsForLpPools());

            let ufoRewardsBefore = await ufoToken.balanceOf(otherAddress1.address);
            await ufoPool.connect(otherAddress1).withdrawVestedUfoMultiple([1]);
            let ufoRewardsAfter = await ufoToken.balanceOf(otherAddress1.address);

            let ufoVestedRewardReceived = ufoRewardsAfter.sub(ufoRewardsBefore);
            expect(ufoVestedRewardReceived).eq(await (await ufoPool.deposits(1)).vestedRewards);

            expect(await stakingFactory.claimedUfoRewardsForUfoPools()).eq(ufoVestedRewardReceived);
        });

        it('Only check APR', async () => {
            await (await ufoToken.connect(otherAddress1).approve(ufoPool.address, amountToStake)).wait();
            await ufoPool.connect(otherAddress1).deposit(amountToStake);

            console.log({ apr: await stakingFactory.getPoolApr(ufoPool.address) });
        });
    });

    describe('All Pools Together', async () => {
        let unlockUfoPool: Staking;
        let unlockedLpPool: Staking;

        let lockedUfoPool1: Staking;
        let lockedLpPool1: Staking;

        let lockedUfoPool2: Staking;
        let lockedLpPool2: Staking;

        let amountToStakeInUnlockUfoPool: BigNumber;
        let amountToStakeInUnlockLpPool: BigNumber;
        let amountToStakeInLockedUfoPool1: BigNumber;
        let amountToStakeInLockedLpPool1: BigNumber;
        let amountToStakeInLockedUfoPool2: BigNumber;
        let amountToStakeInLockedLpPool2: BigNumber;

        beforeEach(async () => {
            amountToStakeInUnlockUfoPool = BigNumber.from(10).pow(21); // 1000 UFO
            amountToStakeInUnlockLpPool = BigNumber.from(10).pow(16);
            amountToStakeInLockedUfoPool1 = BigNumber.from(10).pow(21).mul(3).div(2);
            amountToStakeInLockedLpPool1 = BigNumber.from(10).pow(16).mul(3).div(2);
            amountToStakeInLockedUfoPool2 = BigNumber.from(10).pow(21).mul(2);
            amountToStakeInLockedLpPool2 = BigNumber.from(10).pow(16).mul(2);

            let deployHelper = new DeployHelper(admin);
            unlockUfoPool = await deployHelper.helper.getStaking(await stakingFactory.poolNumberToPoolAddress(0));
            unlockedLpPool = await deployHelper.helper.getStaking(await stakingFactory.poolNumberToPoolAddress(1));
            lockedUfoPool1 = await deployHelper.helper.getStaking(await stakingFactory.poolNumberToPoolAddress(2));
            lockedLpPool1 = await deployHelper.helper.getStaking(await stakingFactory.poolNumberToPoolAddress(3));
            lockedUfoPool2 = await deployHelper.helper.getStaking(await stakingFactory.poolNumberToPoolAddress(4));
            lockedLpPool2 = await deployHelper.helper.getStaking(await stakingFactory.poolNumberToPoolAddress(5));

            await ufoToken.connect(admin).transfer(otherAddress1.address, amountToStakeInUnlockUfoPool);
            await lpToken.connect(admin).transfer(otherAddress1.address, amountToStakeInUnlockLpPool);

            await ufoToken.connect(admin).transfer(otherAddress2.address, amountToStakeInLockedUfoPool1);
            await lpToken.connect(admin).transfer(otherAddress2.address, amountToStakeInLockedLpPool1);

            await ufoToken.connect(admin).transfer(otherAddress3.address, amountToStakeInLockedUfoPool2);
            await lpToken.connect(admin).transfer(otherAddress3.address, amountToStakeInLockedLpPool2);

            // let addresses = [unlockUfoPool, unlockedLpPool, lockedUfoPool1, lockedUfoPool2, lockedUfoPool2, lockedLpPool2].map(a => a.address);
            // console.log(addresses);
            await ufoToken.connect(otherAddress1).approve(unlockUfoPool.address, amountToStakeInUnlockUfoPool);
            await lpToken.connect(otherAddress1).approve(unlockedLpPool.address, amountToStakeInUnlockLpPool);
            await ufoToken.connect(otherAddress2).approve(lockedUfoPool1.address, amountToStakeInLockedUfoPool1);
            await lpToken.connect(otherAddress2).approve(lockedLpPool1.address, amountToStakeInLockedLpPool1);
            await ufoToken.connect(otherAddress3).approve(lockedUfoPool2.address, amountToStakeInLockedUfoPool2);
            await lpToken.connect(otherAddress3).approve(lockedLpPool2.address, amountToStakeInLockedLpPool2);

            await unlockUfoPool.connect(otherAddress1).deposit(amountToStakeInUnlockUfoPool);
            await unlockedLpPool.connect(otherAddress1).deposit(amountToStakeInUnlockLpPool);
            await lockedUfoPool1.connect(otherAddress2).deposit(amountToStakeInLockedUfoPool1);
            await lockedLpPool1.connect(otherAddress2).deposit(amountToStakeInLockedLpPool1);
            await lockedUfoPool2.connect(otherAddress3).deposit(amountToStakeInLockedUfoPool2);
            await lockedLpPool2.connect(otherAddress3).deposit(amountToStakeInLockedLpPool2);
        });

        describe('Withdraw after deposit ends', async () => {
            let plasmaRewardsFromUnlockedUfoPool: BigNumber;
            let plasmaRewardFromUnlockedLpPool: BigNumber;
            let plasmaRewardFromLockedUfoPool1: BigNumber;
            let plasmaRewardFromLockedLpPool1: BigNumber;
            let plasmaRewardFromLockedUfoPool2: BigNumber;
            let plasmaRewardFromLockedLpPool2: BigNumber;

            beforeEach(async () => {
                let currentBlock;
                let deposit;
                let ufoUnstakesAt;

                let plasmaBalanceBefore: BigNumber;
                let plasmaBalanceAfter: BigNumber;

                currentBlock = await getCurrentBlock(network);
                deposit = await unlockUfoPool.deposits(1);
                ufoUnstakesAt = await deposit.unlockBlock.toNumber();
                await mineBlocks(network, ufoUnstakesAt - currentBlock + 1);

                plasmaBalanceBefore = await plasmaToken.balanceOf(otherAddress1.address);
                await unlockUfoPool.connect(otherAddress1).withdrawUfoMultiple([1], zeroAddress);
                plasmaBalanceAfter = await plasmaToken.balanceOf(otherAddress1.address);
                plasmaRewardsFromUnlockedUfoPool = plasmaBalanceAfter.sub(plasmaBalanceBefore);

                plasmaBalanceBefore = await plasmaToken.balanceOf(otherAddress1.address);
                await unlockedLpPool.connect(otherAddress1).withdrawUfoMultiple([1], zeroAddress);
                plasmaBalanceAfter = await plasmaToken.balanceOf(otherAddress1.address);
                plasmaRewardFromUnlockedLpPool = plasmaBalanceAfter.sub(plasmaBalanceBefore);

                currentBlock = await getCurrentBlock(network);
                deposit = await lockedLpPool1.deposits(1);
                ufoUnstakesAt = await deposit.unlockBlock.toNumber();
                await mineBlocks(network, ufoUnstakesAt - currentBlock + 1);
                plasmaBalanceBefore = await plasmaToken.balanceOf(otherAddress2.address);
                await lockedUfoPool1.connect(otherAddress2).withdrawUfoMultiple([1], zeroAddress);
                plasmaBalanceAfter = await plasmaToken.balanceOf(otherAddress2.address);
                plasmaRewardFromLockedUfoPool1 = plasmaBalanceAfter.sub(plasmaBalanceBefore);

                plasmaBalanceBefore = await plasmaToken.balanceOf(otherAddress2.address);
                await lockedLpPool1.connect(otherAddress2).withdrawUfoMultiple([1], zeroAddress);
                plasmaBalanceAfter = await plasmaToken.balanceOf(otherAddress2.address);
                plasmaRewardFromLockedLpPool1 = plasmaBalanceAfter.sub(plasmaBalanceBefore);

                currentBlock = await getCurrentBlock(network);
                deposit = await lockedLpPool2.deposits(1);
                ufoUnstakesAt = await deposit.unlockBlock.toNumber();
                await mineBlocks(network, ufoUnstakesAt - currentBlock + 1);
                plasmaBalanceBefore = await plasmaToken.balanceOf(otherAddress3.address);
                await lockedUfoPool2.connect(otherAddress3).withdrawUfoMultiple([1], zeroAddress);
                plasmaBalanceAfter = await plasmaToken.balanceOf(otherAddress3.address);
                plasmaRewardFromLockedUfoPool2 = plasmaBalanceAfter.sub(plasmaBalanceBefore);

                plasmaBalanceBefore = await plasmaToken.balanceOf(otherAddress3.address);
                await lockedLpPool2.connect(otherAddress3).withdrawUfoMultiple([1], zeroAddress);
                plasmaBalanceAfter = await plasmaToken.balanceOf(otherAddress3.address);
                plasmaRewardFromLockedLpPool2 = plasmaBalanceAfter.sub(plasmaBalanceBefore);
            });

            it('Plasma Rewards', async () => {
                let [
                    _plasmaRewardsFromUnlockedUfoPool,
                    _plasmaRewardFromUnlockedLpPool,
                    _plasmaRewardFromLockedUfoPool1,
                    _plasmaRewardFromLockedLpPool1,
                    _plasmaRewardFromLockedUfoPool2,
                    _plasmaRewardFromLockedLpPool2,
                ] = [
                    plasmaRewardsFromUnlockedUfoPool,
                    plasmaRewardFromUnlockedLpPool,
                    plasmaRewardFromLockedUfoPool1,
                    plasmaRewardFromLockedLpPool1,
                    plasmaRewardFromLockedUfoPool2,
                    plasmaRewardFromLockedLpPool2,
                ].map((a) => a.toString());

                console.log({
                    _plasmaRewardsFromUnlockedUfoPool,
                    _plasmaRewardFromUnlockedLpPool,
                    _plasmaRewardFromLockedUfoPool1,
                    _plasmaRewardFromLockedLpPool1,
                    _plasmaRewardFromLockedUfoPool2,
                    _plasmaRewardFromLockedLpPool2,
                });
            });

            async function getVestedReward(pool: Staking, user: SignerWithAddress): Promise<BigNumber> {
                let ufoBalanceBefore = await ufoToken.balanceOf(user.address);
                await pool.connect(user).withdrawVestedUfoMultiple([1]);
                let ufoBalanceAfter = await ufoToken.balanceOf(user.address);
                return ufoBalanceAfter.sub(ufoBalanceBefore);
            }

            it('Update Plasma reward for all pools', async () => {
                await stakingFactory.connect(admin).changeUfoPoolPlasmaPerBlock(1);
                await stakingFactory.connect(admin).changeLpPoolPlasmaPerBlock(2);

                expect(await stakingFactory.ufoPoolPlasmaPerBlock()).eq(1);
                expect(await stakingFactory.lpPoolPlasmaPerBlock()).eq(2);
            });

            it('Change Number of vested rewards', async () => {
                await stakingFactory.connect(admin).changeUfoRewardsForLpPools(BigNumber.from(10).pow(18).mul(750));
                await stakingFactory.connect(admin).changeUfoRewardsForUfoPools(BigNumber.from(10).pow(18).mul(250));
            });

            it('Claim Vested Rewards', async () => {
                await ufoToken.connect(admin).transfer(stakingFactory.address, BigNumber.from(10).pow(22));
                console.log({ totalBlocks: await (await lockedLpPool1.totalBlocksPerYear()).toNumber() });
                await mineBlocks(network, await (await lockedLpPool1.totalBlocksPerYear()).toNumber());

                let ufoRewardsFromUnlockedUfoPool: BigNumber = await getVestedReward(unlockUfoPool, otherAddress1);
                let ufoRewardFromUnlockedLpPool: BigNumber = await getVestedReward(unlockedLpPool, otherAddress1);
                let ufoRewardFromLockedUfoPool1: BigNumber = await getVestedReward(lockedUfoPool1, otherAddress2);
                let ufoRewardFromLockedLpPool1: BigNumber = await getVestedReward(lockedLpPool1, otherAddress2);
                let ufoRewardFromLockedUfoPool2: BigNumber = await getVestedReward(lockedUfoPool2, otherAddress3);
                let ufoRewardFromLockedLpPool2: BigNumber = await getVestedReward(lockedLpPool2, otherAddress3);

                let [
                    _ufoRewardsFromUnlockedUfoPool,
                    _ufoRewardFromUnlockedLpPool,
                    _ufoRewardFromLockedUfoPool1,
                    _ufoRewardFromLockedLpPool1,
                    _ufoRewardFromLockedUfoPool2,
                    _ufoRewardFromLockedLpPool2,
                ] = [
                    ufoRewardsFromUnlockedUfoPool,
                    ufoRewardFromUnlockedLpPool,
                    ufoRewardFromLockedUfoPool1,
                    ufoRewardFromLockedLpPool1,
                    ufoRewardFromLockedUfoPool2,
                    ufoRewardFromLockedLpPool2,
                ].map((a) => a.toString());

                console.log({
                    _ufoRewardsFromUnlockedUfoPool,
                    _ufoRewardFromUnlockedLpPool,
                    _ufoRewardFromLockedUfoPool1,
                    _ufoRewardFromLockedLpPool1,
                    _ufoRewardFromLockedUfoPool2,
                    _ufoRewardFromLockedLpPool2,
                });
            });
        });
    });

    describe('Unlocked UFO Pool, Locked UFO Pool_1, Locked UFO Pool_2', async () => {
        let unlockedUfoPool: Staking;
        let lockedUfoPool1: Staking;
        let lockedUfoPool2: Staking;

        let amountToStake: BigNumber;

        beforeEach(async () => {
            let ufoPoolAddress = await stakingFactory.poolNumberToPoolAddress(0);
            let deployHelper = new DeployHelper(admin);
            unlockedUfoPool = await deployHelper.helper.getStaking(ufoPoolAddress);

            let ufoPoolAddress1 = await stakingFactory.poolNumberToPoolAddress(2);
            lockedUfoPool1 = await deployHelper.helper.getStaking(ufoPoolAddress1);

            let ufoPoolAddress2 = await stakingFactory.poolNumberToPoolAddress(4);
            lockedUfoPool2 = await deployHelper.helper.getStaking(ufoPoolAddress2);

            amountToStake = BigNumber.from(10).pow(20); // 100 UFO
            await ufoToken.connect(admin).transfer(otherAddress1.address, amountToStake); // 100 UFO
            await ufoToken.connect(admin).transfer(otherAddress1.address, amountToStake); // 100 UFO
            await ufoToken.connect(admin).transfer(otherAddress1.address, amountToStake); // 100 UFO

            await ufoToken.connect(otherAddress1).approve(unlockedUfoPool.address, amountToStake);
            await ufoToken.connect(otherAddress1).approve(lockedUfoPool1.address, amountToStake);
            await ufoToken.connect(otherAddress1).approve(lockedUfoPool2.address, amountToStake);

            await unlockedUfoPool.connect(otherAddress1).deposit(amountToStake);
            await lockedUfoPool1.connect(otherAddress1).deposit(amountToStake);
            await lockedUfoPool2.connect(otherAddress1).deposit(amountToStake);
        });

        // deposit number likely 1 accross all contracts
        it('withdrawals should fail for locked pools and succeed for unlocked pool', async () => {
            await unlockedUfoPool.connect(otherAddress1).withdrawUfoMultiple([1], otherAddress1.address);
            await expect(lockedUfoPool1.connect(otherAddress1).withdrawUfoMultiple([1], otherAddress1.address)).to.be.revertedWith(
                await errors.ONLY_AFTER_END_BLOCK()
            );
            await expect(lockedUfoPool2.connect(otherAddress1).withdrawUfoMultiple([1], zeroAddress)).to.be.revertedWith(
                await errors.ONLY_AFTER_END_BLOCK()
            );
        });

        it('withdraw from lockerufopool1', async () => {
            let deposit = await lockedUfoPool1.deposits(1);
            let ufoUnstakesAt = await deposit.unlockBlock.toNumber();
            let currentBlock = await getCurrentBlock(network);

            await mineBlocks(network, ufoUnstakesAt - currentBlock + 1);
            await lockedUfoPool1.connect(otherAddress1).withdrawUfoMultiple([1], zeroAddress);
            await expect(lockedUfoPool2.connect(otherAddress1).withdrawUfoMultiple([1], zeroAddress)).to.be.revertedWith(
                await errors.ONLY_AFTER_END_BLOCK()
            );
        });

        it('withdraw from lockerufopool2', async () => {
            let deposit = await lockedUfoPool2.deposits(1);
            let ufoUnstakesAt = await deposit.unlockBlock.toNumber();
            let currentBlock = await getCurrentBlock(network);

            await mineBlocks(network, ufoUnstakesAt - currentBlock + 1);
            await lockedUfoPool1.connect(otherAddress1).withdrawUfoMultiple([1], zeroAddress);
            await lockedUfoPool2.connect(otherAddress1).withdrawUfoMultiple([1], zeroAddress);
        });

        async function claimVestedReward(pool: Staking, user: SignerWithAddress): Promise<[BigNumber, BigNumber]> {
            let plasmaBalanceBefore = await plasmaToken.balanceOf(user.address);
            let ufoTokensBefore = await ufoToken.balanceOf(user.address);
            await pool.connect(user).withdrawVestedUfoMultiple([1]);
            let plasmaBalanceAfter = await plasmaToken.balanceOf(user.address);
            let ufoTokensAfter = await ufoToken.balanceOf(user.address);
            return [plasmaBalanceAfter.sub(plasmaBalanceBefore), ufoTokensAfter.sub(ufoTokensBefore)];
        }

        it('withdrawVested all vested rewards and compare', async () => {
            await ufoToken.connect(admin).transfer(stakingFactory.address, await stakingFactory.ufoRewardsForLpPools());
            await ufoToken.connect(admin).transfer(stakingFactory.address, await stakingFactory.ufoRewardsForUfoPools());

            console.log({
                ufoRewardsForUfoPools: await (await stakingFactory.ufoRewardsForUfoPools()).toString(),
                ufoRewardsForLpPools: await (await stakingFactory.ufoRewardsForLpPools()).toString(),
            });

            let deposit = await lockedUfoPool2.deposits(1);
            let ufoUnstakesAt = await deposit.unlockBlock.toNumber();
            let currentBlock = await getCurrentBlock(network);

            await mineBlocks(network, ufoUnstakesAt - currentBlock + 1);

            await unlockedUfoPool.connect(otherAddress1).withdrawUfoMultiple([1], zeroAddress);
            await lockedUfoPool1.connect(otherAddress1).withdrawUfoMultiple([1], otherAddress1.address);
            await lockedUfoPool2.connect(otherAddress1).withdrawUfoMultiple([1], zeroAddress);

            let oneYearBlocks = await (await unlockedUfoPool.totalBlocksPerYear()).toNumber();
            await mineBlocks(network, oneYearBlocks);

            let [plasmaRecevied_unlockPool, ufoTokenReceived_unlockPool] = await (
                await claimVestedReward(unlockedUfoPool, otherAddress1)
            ).map((a) => a.toString());
            let [plasmaRecevied_lockPool1, ufoTokenReceived_lockPool1] = await (
                await claimVestedReward(lockedUfoPool1, otherAddress1)
            ).map((a) => a.toString());
            let [plasmaRecevied_lockPool2, ufoTokenReceived_lockPool2] = await (
                await claimVestedReward(lockedUfoPool2, otherAddress1)
            ).map((a) => a.toString());

            console.log({
                plasmaRecevied_unlockPool,
                ufoTokenReceived_unlockPool,
                plasmaRecevied_lockPool1,
                ufoTokenReceived_lockPool1,
                plasmaRecevied_lockPool2,
                ufoTokenReceived_lockPool2,
            });
        });
    });

    async function getCurrentBlock(_network: Network): Promise<number> {
        let currentBlockNumber = await _network.provider.request({
            method: 'eth_blockNumber',
            params: [],
        });

        return BigNumber.from(currentBlockNumber).toNumber();
    }

    async function mineBlocks(_network: Network, numberOfBlocks: number): Promise<void> {
        for (let index = 0; index < numberOfBlocks; index++) {
            await _network.provider.request({
                method: 'evm_mine',
                params: [],
            });
        }
        return;
    }
});
