import { ethers, network } from 'hardhat';
import { expect } from 'chai';

import DeployHelper from '../utils/deployer';
import { UAP, TransparentUpgradeableProxy } from '../typechain';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { zeroAddress } from '../utils/constants';

describe('UAP', async () => {
    let uapTokenContract: UAP;
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
    });

    it("Can't initialize twice", async () => {
        await expect(uapTokenContract.connect(admin).initialize(admin.address, minter.address)).to.be.revertedWith(
            'Initializable: contract is already initialized'
        );
    });

    it('Check owner/admin', async () => {
        expect(await uapTokenContract.connect(admin).admin()).eq(admin.address);
    });

    it('Only Minter can mint the amount', async () => {
        await expect(uapTokenContract.connect(minter).mint(randomUser1.address, '100'))
            .to.emit(uapTokenContract, 'Transfer')
            .withArgs(zeroAddress, randomUser1.address, '100');

        await expect(uapTokenContract.connect(admin).mint(randomUser1.address, 100)).to.be.revertedWith('Only Minter can mint the token');
    });
});
