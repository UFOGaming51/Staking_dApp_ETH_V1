import { ethers, network } from 'hardhat';
import { expect } from 'chai';

import DeployHelper from '../utils/deployer';
import { RobotPassive1, XToken, UAP, TransparentUpgradeableProxy } from '../typechain';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { zeroAddress } from '../utils/constants';
import { BigNumber, BigNumberish } from '@ethersproject/bignumber';

describe('Robot Passive Part', async () => {
    let uapTokenContract: UAP;
    let ufo: XToken;
    let robotPassive: RobotPassive1;

    let proxyAdmin: SignerWithAddress;
    let admin: SignerWithAddress;
    let randomUser1: SignerWithAddress;
    let randomUser2: SignerWithAddress;
    let randomUser3: SignerWithAddress;
    let minter: SignerWithAddress;

    beforeEach(async () => {
        [, proxyAdmin, admin, , , randomUser1, , , randomUser2, , , , , randomUser3, , , minter] = await ethers.getSigners();
        let deployHelper: DeployHelper = new DeployHelper(proxyAdmin);
        let uapLogic: UAP = await deployHelper.matic.deployUAP();
        let proxy: TransparentUpgradeableProxy = await deployHelper.helper.deployTransparentUpgradableProxy(
            uapLogic.address,
            proxyAdmin.address
        );
        uapTokenContract = await deployHelper.matic.getUAP(proxy.address);
        await uapTokenContract.connect(admin).initialize(admin.address, minter.address);
        await uapTokenContract.connect(minter).mint(admin.address, '1900000000000000000000000');

        ufo = await deployHelper.helper.deployXToken('UFO', 'UFO', BigNumber.from('0'), admin.address);
        await ufo.connect(admin).mint(admin.address, '1000000000000004534300000');

        let robotPassive1Logic: RobotPassive1 = await deployHelper.nft.deployRobotPassive1();
        proxy = await deployHelper.helper.deployTransparentUpgradableProxy(robotPassive1Logic.address, proxyAdmin.address);
        robotPassive = await deployHelper.nft.getRobotPassive1(proxy.address);
        await robotPassive.connect(admin).initialize(admin.address, uapTokenContract.address, ufo.address);
    });

    it('Transfer to other address should fail', async () => {
        await robotPassive.connect(admin).createNew(1, randomUser1.address);
        const firstNFT = await robotPassive.connect(admin).totalSupply();

        await robotPassive.connect(randomUser1).approve(admin.address, firstNFT);
        await expect(
            robotPassive.connect(admin)['safeTransferFrom(address,address,uint256)'](randomUser1.address, admin.address, firstNFT)
        ).to.be.revertedWith('Robot Parts are non-transferable');
    });
});
