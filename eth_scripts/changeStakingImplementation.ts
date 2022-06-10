import { ethers, run } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

import DeployHelper from '../utils/deployer';
import { BigNumber } from 'ethers';
import { goerli } from './config.json';

async function main() {
    let [admin, user1]: SignerWithAddress[] = await ethers.getSigners();
    let deployHelper = new DeployHelper(admin);
    let beacon = await deployHelper.helper.getBeacon(goerli.beacon);

    console.log({ oldImplementation: await beacon.impl() });
    console.log('Deploying staking');
    let stakingImplementation = await deployHelper.helper.deployStaking(goerli.plasma, goerli.erc20Predicate, goerli.rootChainManager);
    await stakingImplementation.deployTransaction.wait(6);

    await run('verify:verify', {
        address: stakingImplementation.address,
        constructorArguments: [goerli.plasma, goerli.erc20Predicate, goerli.rootChainManager],
        contract: 'contracts/ethereum/Staking.sol:Staking',
    }).catch(console.log);

    console.log('changing implementation');
    await (await beacon.upgradeImplementation(stakingImplementation.address)).wait();

    console.log({ newImplementation: await beacon.impl() });
}

main().then(console.log);
