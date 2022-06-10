import { ethers, run } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

import DeployHelper from '../utils/deployer';
import { BigNumber } from 'ethers';

async function main() {
    let [admin, user1]: SignerWithAddress[] = await ethers.getSigners();
    let deployHelper = new DeployHelper(admin);

    /**
     * for goerli net
     */
    let ufoToken = await (
        await deployHelper.helper.deployXToken('UFO Token', 'UFO', BigNumber.from(10).pow(18).mul('51000000000'), admin.address)
    ).deployed();
    console.log('ufoToken address on goerli - ', ufoToken.address);
}

main();
