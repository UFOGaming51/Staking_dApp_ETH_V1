import { ethers, run } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumber } from 'ethers';
import DeployHelper from '../utils/deployer';
import * as config from './config.json';
import { goerli } from './config.json';

async function main() {
    let [admin, user1]: SignerWithAddress[] = await ethers.getSigners();
    let deployHelper = new DeployHelper(admin);
    let ufoVestedRewardsForUfo = BigNumber.from(10).pow(18).mul('321969696969');
    let ufoVestedRewardsForLp = BigNumber.from(10).pow(18).mul('965909090909');

    let stakingFactory = await deployHelper.helper.getStakingFactory('0xAfF77836B743E9923a12d3B18f710b1F8aac2a55');
    let plasmaToken = await deployHelper.eth.getPlasma(goerli.plasma);

    let totalPools = await stakingFactory.totalPools();
    for (let index = 0; index < totalPools.toNumber(); index++) {
        console.log(`Adding pool to ${index} / ${totalPools.toNumber()} as minter to plasma token`);
        let poolAddress = await stakingFactory.poolNumberToPoolAddress(index);
        await (await plasmaToken.connect(admin).addMinter(poolAddress)).wait();
    }

    console.log('Tranfering tokens to staking factory for vests');
    let ufoToken = await deployHelper.helper.getXToken(goerli.ufoToken);
    await (await ufoToken.mint(stakingFactory.address, ufoVestedRewardsForLp.add(ufoVestedRewardsForUfo))).wait();

    return 'Done';
}

main();
