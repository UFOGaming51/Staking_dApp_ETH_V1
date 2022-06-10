import { ethers, run } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

import DeployHelper from '../utils/deployer';
import * as config from './config.json';

async function main() {
    let [admin, user1]: SignerWithAddress[] = await ethers.getSigners();
    let deployHelper = new DeployHelper(admin);
    let customBridge = await deployHelper.helper.deployCustomBridge(
        config.goerli.erc20Predicate,
        config.goerli.rootChainManager,
        config.goerli.plasma
    );

    await customBridge.deployTransaction.wait(5);

    await run('verify:verify', {
        address: customBridge.address,
        constructorArguments: [config.goerli.erc20Predicate, config.goerli.rootChainManager, config.goerli.plasma],
        contract: 'contracts/CustomBridge.sol:CustomBridge',
    });
}

main();
