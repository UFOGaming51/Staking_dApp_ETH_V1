import { ethers, run } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import DeployHelper from '../utils/deployer';
import { goerli } from './config.json';
import { BigNumber } from 'ethers';

async function main() {
    // await depositToStakingContract();
    // await claimPlasma();
    await withdraw();
    return 'done';
}

async function withdraw() {
    let [admin, user1]: SignerWithAddress[] = await ethers.getSigners();
    let deployHelper = new DeployHelper(admin);
    let stakingFactory = await deployHelper.helper.getStakingFactory(goerli.stakingFactory);

    let firstPoolAddress = await stakingFactory.poolNumberToPoolAddress(0);
    let secondPoolAddress = await stakingFactory.poolNumberToPoolAddress(1);
    console.log({ firstPoolAddress, secondPoolAddress });

    let firstPool = await deployHelper.helper.getStaking(firstPoolAddress);
    let secondPool = await deployHelper.helper.getStaking(secondPoolAddress);

    await firstPool.connect(user1).withdrawUfo(1);
    await secondPool.connect(user1).withdrawUfo(1);
}

async function claimPlasma() {
    let [admin, user1]: SignerWithAddress[] = await ethers.getSigners();
    let deployHelper = new DeployHelper(admin);
    let stakingFactory = await deployHelper.helper.getStakingFactory(goerli.stakingFactory);

    let firstPoolAddress = await stakingFactory.poolNumberToPoolAddress(0);
    let secondPoolAddress = await stakingFactory.poolNumberToPoolAddress(1);
    console.log({ firstPoolAddress, secondPoolAddress });

    let firstPool = await deployHelper.helper.getStaking(firstPoolAddress);
    let secondPool = await deployHelper.helper.getStaking(secondPoolAddress);

    await (await firstPool.connect(user1).claimPlasma(1)).wait();
    await (await secondPool.connect(user1).claimPlasma(1)).wait();
}

async function depositToStakingContract() {
    let maxNumber = BigNumber.from(10).pow(77);

    let firstAmountToDeposit = BigNumber.from(10).pow(18).mul(78234).div(2000);
    let secondAmountToDeposit = BigNumber.from(10).pow(14).mul(1287).div(2000);

    let [admin, user1]: SignerWithAddress[] = await ethers.getSigners();
    let deployHelper = new DeployHelper(admin);
    let stakingFactory = await deployHelper.helper.getStakingFactory(goerli.stakingFactory);

    let firstPoolAddress = await stakingFactory.poolNumberToPoolAddress(0);
    let secondPoolAddress = await stakingFactory.poolNumberToPoolAddress(1);
    console.log({ firstPoolAddress, secondPoolAddress });

    let firstPool = await deployHelper.helper.getStaking(firstPoolAddress);
    let secondPool = await deployHelper.helper.getStaking(secondPoolAddress);

    let stakingTokenForFirstPool = await firstPool.stakingToken();
    let stakingTokenForSecondPool = await secondPool.stakingToken();

    let firstToken = await deployHelper.helper.getXToken(stakingTokenForFirstPool);
    let secondToken = await deployHelper.helper.getXToken(stakingTokenForSecondPool);

    // console.log({ firstToken: firstToken.address, secondToken: secondToken.address });
    console.log('Starting Transfers');
    await (await firstToken.transfer(user1.address, firstAmountToDeposit)).wait();
    await (await secondToken.transfer(user1.address, secondAmountToDeposit)).wait();

    console.log('Starting approvals to max for all tokens and pools');
    await (await firstToken.connect(user1).approve(firstPool.address, maxNumber)).wait();
    await (await firstToken.connect(user1).approve(secondPool.address, maxNumber)).wait();

    await (await secondToken.connect(user1).approve(firstPool.address, maxNumber)).wait();
    await (await secondToken.connect(user1).approve(secondPool.address, maxNumber)).wait();

    // console.log({ firstAllowance: await (await firstToken.allowance(user1.address, firstPool.address)).toString() });
    // console.log({ balanceAvailable1: await firstToken.balanceOf(user1.address) });
    // console.log({ balanceAvailable2: await secondToken.balanceOf(user1.address) });
    console.log('Starting deposits');
    await (await firstPool.connect(user1).deposit(firstAmountToDeposit)).wait();
    await (await secondPool.connect(user1).deposit(secondAmountToDeposit)).wait();

    console.log({ stakingTokenForFirstPool, stakingTokenForSecondPool });
}
main().then(console.log).catch(console.log);
