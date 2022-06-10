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
        let ab = await getCurrentBlockTimeStamp(network);
        await mineBlockandSetTimeStamp(network, 10000);
        ab = await getCurrentBlockTimeStamp(network);
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

    it('A', async () => {
        let ab = await getCurrentBlockTimeStamp(network);
        await mineBlockandSetTimeStamp(network, 10000);
        ab = await getCurrentBlockTimeStamp(network);
    });

    it('b', async () => {
        let ab = await getCurrentBlockTimeStamp(network);
        await mineBlockandSetTimeStamp(network, 10000);
        ab = await getCurrentBlockTimeStamp(network);
    });

    async function getCurrentBlockTimeStamp(_network: Network): Promise<number> {
        const blockNumAfter = await ethers.provider.getBlockNumber();
        const blockAfter = await ethers.provider.getBlock(blockNumAfter);
        const timestampAfter = blockAfter.timestamp;
        console.log('current blockNumber', blockNumAfter);
        console.log('current timestamp', timestampAfter);
        return BigNumber.from(timestampAfter).toNumber();
    }

    async function mineBlockandSetTimeStamp(_network: Network, addTimeStamps: number): Promise<void> {
        const blockNumAfter = await ethers.provider.getBlockNumber();
        const blockAfter = await ethers.provider.getBlock(blockNumAfter);
        const timestampAfter = blockAfter.timestamp;

        await _network.provider.send('evm_setNextBlockTimestamp', [timestampAfter + addTimeStamps]);
        await _network.provider.send('evm_mine');
        return;
    }
});
