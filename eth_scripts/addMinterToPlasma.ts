import { ethers, run } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

import DeployHelper from '../utils/deployer';
import * as config from './config.json';

async function main() {
    let [admin, user1]: SignerWithAddress[] = await ethers.getSigners();
    let deployHelper = new DeployHelper(admin);

    let plasma = await deployHelper.eth.getPlasma(config.goerli.plasma);
    await (await plasma.addMinter(config.goerli.customBridge)).wait(2);
}

main();
