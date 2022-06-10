import { ethers, run } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

import DeployHelper from '../utils/deployer';
import { mainnet } from './config.json';

async function main() {
    let [admin, user1]: SignerWithAddress[] = await ethers.getSigners();
    let deployHelper = new DeployHelper(admin);

    /**
     * for goerli net
     */
    let plasma = await (await deployHelper.eth.deployPlasma('Plasma Points', 'PP', admin.address)).deployed();
    console.log('plasma address on goerli - ', plasma.address);
    await run('verify:verify', {
        address: plasma.address,
        constructorArguments: ['Plasma Points', 'PP', admin.address],
        contract: 'contracts/ethereum/Plasma.sol:Plasma',
    });

    /**
     * for main net
     */
    // let plasma = await (await deployHelper.eth.deployPlasma('Plasma Points', 'PP', admin.address)).deployed();

    // await run('verify:verify', {
    //     address: mainnet.plasma,
    //     constructorArguments: ['Plasma Points', 'PP', admin.address],
    //     contract: 'contracts/ethereum/Plasma.sol:Plasma',
    // });
}

main();
