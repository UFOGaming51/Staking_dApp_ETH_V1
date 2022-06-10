import { ethers, run } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

import DeployHelper from '../utils/deployer';
import { BigNumber } from 'ethers';
import { mainnet } from './config.json';

async function main() {
    let [admin, user1]: SignerWithAddress[] = await ethers.getSigners();
    let customAdminAddress = "0x5CBAbBe5b09a080444d848444e1081eCF7B8ad10";

    let deployHelper = new DeployHelper(admin);
    let ufoVestedRewardsForUfo = BigNumber.from(10).pow(18).mul('321969696969');
    let ufoVestedRewardsForLp = BigNumber.from(10).pow(18).mul('965909090909');

    let totalPlasmaRewards = BigNumber.from(10).pow(18).mul('29500000');
    let plasmaRewardsForUfoPools = totalPlasmaRewards.div(4);
    let plasmaRewardsForLpPools = totalPlasmaRewards.mul(3).div(4);
    // let ufoToken = await (
    //     await deployHelper.helper.deployXToken('UFO Token', 'UFO', BigNumber.from(10).pow(18).mul('51000000000'), customAdminAddress)
    // ).deployed();
    // await induceDelay(20000);
    // await run('verify:verify', {
    //     address: ufoToken.address,
    //     constructorArguments: ['UFO Token', 'UFO', BigNumber.from(10).pow(18).mul('51000000000').toString(), customAdminAddress],
    //     contract: 'contracts/XToken.sol:XToken',
    // }).catch(console.log);

    // let lpToken = await (
    //     await deployHelper.helper.deployXToken('UFO-ETH-LP', 'LP', BigNumber.from(10).pow(18).mul(12).div(10), customAdminAddress)
    // ).deployed();
    // await induceDelay(20001);

    // await run('verify:verify', {
    //     address: lpToken.address,
    //     constructorArguments: ['UFO-ETH-LP', 'LP', BigNumber.from(10).pow(18).mul(12).div(10).toString(), customAdminAddress],
    //     contract: 'contracts/XToken.sol:XToken',
    // }).catch(console.log);

    // let mockRootChainManager = await (await deployHelper.helper.deployMockRootChainManager()).deployed();

    console.log('Deploying staking');
    let stakingImplementation = await deployHelper.helper.deployStaking(mainnet.plasma, mainnet.erc20Predicate, mainnet.rootChainManager);
    await stakingImplementation.deployTransaction.wait();

    console.log('Deploying beacon');
    let beacon = await deployHelper.helper.deployBeacon(customAdminAddress, stakingImplementation.address);
    await beacon.deployTransaction.wait();

    console.log('Deploying staking factory');
    let stakingFactory = await (
        await deployHelper.helper.deployStakingFactory(
            beacon.address,
            customAdminAddress,
            ufoVestedRewardsForUfo,
            ufoVestedRewardsForLp,
            mainnet.ufoToken,
            mainnet.ufoToken,
            mainnet.lpToken
        )
    ).deployed();

    await stakingFactory.deployTransaction.wait(6);

    await run('verify:verify', {
        address: stakingImplementation.address,
        constructorArguments: [mainnet.plasma, mainnet.erc20Predicate, mainnet.rootChainManager],
        contract: 'contracts/ethereum/Staking.sol:Staking',
    }).catch(console.log);

    await run('verify:verify', {
        address: beacon.address,
        constructorArguments: [customAdminAddress, stakingImplementation.address],
        contract: 'contracts/ethereum/Beacon.sol:Beacon',
    }).catch(console.log);

    await run('verify:verify', {
        address: stakingFactory.address,
        constructorArguments: [
            beacon.address,
            customAdminAddress,
            ufoVestedRewardsForUfo,
            ufoVestedRewardsForLp,
            mainnet.ufoToken,
            mainnet.ufoToken,
            mainnet.lpToken,
        ],
        contract: 'contracts/ethereum/StakingFactory.sol:StakingFactory',
    }).catch(console.log);

    let plasmaToken = await deployHelper.eth.getPlasma(mainnet.plasma);

    let totalPools = await stakingFactory.totalPools();

    const allUfoPools: string[] = [];
    const allLpPools: string[] = [];

    for (let index = 0; index < totalPools.toNumber(); index++) {
        let poolAddress = await stakingFactory.poolNumberToPoolAddress(index);
        if (index % 2 == 0) {
            allUfoPools.push(poolAddress);
        } else {
            allLpPools.push(poolAddress);
        }
    }

    console.log('Updating Plasma RPB');
    // let pool = await deployHelper.helper.getStaking(await stakingFactory.poolNumberToPoolAddress(0));
    // let ufoPoolPlasmaRpb = plasmaRewardsForUfoPools.div(await pool.totalBlocksPerYear());
    // let lpPoolPlasmaRpb = plasmaRewardsForLpPools.div(await pool.totalBlocksPerYear());

    await (await stakingFactory.connect(admin).changeUfoPoolPlasmaRewards(plasmaRewardsForUfoPools)).wait();
    await (await stakingFactory.connect(admin).changeLpPoolPlasmaRewards(plasmaRewardsForLpPools)).wait();

    console.log('Deploying staking helper');
    const stakingHelper = await deployHelper.helper.deployDepositHelper(allUfoPools, allLpPools, mainnet.ufoToken, mainnet.lpToken);
    await stakingHelper.deployTransaction.wait(6);

    await run('verify:verify', {
        address: stakingHelper.address,
        constructorArguments: [allUfoPools, allLpPools, mainnet.ufoToken, mainnet.lpToken],
        contract: 'contracts/ethereum/DepositHelper.sol:DepositHelper',
    }).catch(console.log);

    console.log({
        stakingFactory: stakingFactory.address,
        beacon: beacon.address,
        stakingImplementation: stakingImplementation.address,
        stakingHelper: stakingHelper.address,
    });

    // let stakingFactory = await deployHelper.helper.getStakingFactory(mainnet.stakingFactory);
    // let plasmaToken = await deployHelper.eth.getPlasma(mainnet.plasma);

    // let totalPools = await stakingFactory.totalPools();

    const mintersToAdd = [];
    
    for (let index = 0; index < totalPools.toNumber(); index++) {
        // console.log(`Adding pool to ${index} / ${totalPools.toNumber()} as minter to plasma token`);
        let poolAddress = await stakingFactory.poolNumberToPoolAddress(index);
        // await (await plasmaToken.connect(admin).addMinter(poolAddress)).wait();
        mintersToAdd.push(poolAddress);
    }

    console.log("Add the below minters to plasma token address");
    console.log(mintersToAdd);

    console.log('Tranfering tokens to staking factory for vests');
    let ufoToken = await deployHelper.helper.getXToken(mainnet.ufoToken);
    await (await ufoToken.mint(stakingFactory.address, ufoVestedRewardsForLp.add(ufoVestedRewardsForUfo))).wait();

    return 'Done';
}

main().then(console.log).catch(console.log);
