import { ethers, network } from 'hardhat';
import { expect } from 'chai';

import DeployHelper from '../utils/deployer';
import { UAP, TransparentUpgradeableProxy, XToken, PrimaryGun } from '../typechain';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { zeroAddress } from '../utils/constants';
import { BigNumber, BigNumberish } from '@ethersproject/bignumber';

describe('Primary Gun', async () => {
    let uapTokenContract: UAP;
    let ufo: XToken;
    let primaryGun: PrimaryGun;

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

        let primaryGunLogic: PrimaryGun = await deployHelper.nft.deployPrimaryGun();
        proxy = await deployHelper.helper.deployTransparentUpgradableProxy(primaryGunLogic.address, proxyAdmin.address);
        primaryGun = await deployHelper.nft.getPrimaryGun(proxy.address);
        await primaryGun.connect(admin).initialize(admin.address, uapTokenContract.address, ufo.address);
    });

    it('Create New NFT', async () => {
        await primaryGun.connect(admin).createNew(0, admin.address);
        expect(await primaryGun.connect(admin).totalSupply()).eq(1);

        expect(await (await primaryGun.connect(admin).nftProperites(1)).rarity).eq(0);
        expect(await (await primaryGun.connect(admin).nftProperites(1)).level).eq(0);

        await primaryGun.connect(admin).createNew(3, admin.address);
        expect(await primaryGun.connect(admin).totalSupply()).eq(2);

        expect(await (await primaryGun.connect(admin).nftProperites(2)).rarity).eq(3);
        expect(await (await primaryGun.connect(admin).nftProperites(2)).level).eq(0);
    });

    it('Should revert of invalid type of rarity is used to create the NFT', async () => {
        await expect(primaryGun.connect(admin).createNew(4, admin.address)).to.be.reverted;
    });

    it('Upgrade NFT', async () => {
        await primaryGun.connect(admin).createNew(0, admin.address);
        const firstNFT = await primaryGun.connect(admin).totalSupply();

        await ufo.connect(admin).approve(primaryGun.address, '109000000000223400000000');
        await uapTokenContract.connect(admin).approve(primaryGun.address, '1099111123423111111111');

        await expect(primaryGun.connect(admin).upgradeNFT(firstNFT)).to.emit(primaryGun, 'UpgradedNFT').withArgs(firstNFT, 0, 1);
        await expect(primaryGun.connect(admin).upgradeNFT(firstNFT)).to.emit(primaryGun, 'UpgradedNFT').withArgs(firstNFT, 0, 2);
        await expect(primaryGun.connect(admin).upgradeNFT(firstNFT)).to.emit(primaryGun, 'UpgradedNFT').withArgs(firstNFT, 0, 3);
        await expect(primaryGun.connect(admin).upgradeNFT(firstNFT)).to.emit(primaryGun, 'UpgradedNFT').withArgs(firstNFT, 0, 4);
    });

    it('White NFT can be upgraded only 4 times, 5th time it revert', async () => {
        await primaryGun.connect(admin).createNew(0, admin.address);
        const firstNFT = await primaryGun.connect(admin).totalSupply();

        await ufo.connect(admin).approve(primaryGun.address, '109000000000223400000000');
        await uapTokenContract.connect(admin).approve(primaryGun.address, '1099111123423111111111');

        await expect(primaryGun.connect(admin).upgradeNFT(firstNFT)).to.emit(primaryGun, 'UpgradedNFT').withArgs(firstNFT, 0, 1);
        await expect(primaryGun.connect(admin).upgradeNFT(firstNFT)).to.emit(primaryGun, 'UpgradedNFT').withArgs(firstNFT, 0, 2);
        await expect(primaryGun.connect(admin).upgradeNFT(firstNFT)).to.emit(primaryGun, 'UpgradedNFT').withArgs(firstNFT, 0, 3);
        await expect(primaryGun.connect(admin).upgradeNFT(firstNFT)).to.emit(primaryGun, 'UpgradedNFT').withArgs(firstNFT, 0, 4);
        await expect(primaryGun.connect(admin).upgradeNFT(firstNFT)).to.be.revertedWith('White and Green rarity NFT have max level Four');
    });

    it('Blue NFT can be upgraded only 5 times, 6th time it reverts', async () => {
        await primaryGun.connect(admin).createNew(3, admin.address);
        const firstNFT = await primaryGun.connect(admin).totalSupply();

        await ufo.connect(admin).approve(primaryGun.address, '109000000000223400000000');
        await uapTokenContract.connect(admin).approve(primaryGun.address, '1099111123423111111111');

        await expect(primaryGun.connect(admin).upgradeNFT(firstNFT)).to.emit(primaryGun, 'UpgradedNFT').withArgs(firstNFT, 3, 1);
        await expect(primaryGun.connect(admin).upgradeNFT(firstNFT)).to.emit(primaryGun, 'UpgradedNFT').withArgs(firstNFT, 3, 2);
        await expect(primaryGun.connect(admin).upgradeNFT(firstNFT)).to.emit(primaryGun, 'UpgradedNFT').withArgs(firstNFT, 3, 3);
        await expect(primaryGun.connect(admin).upgradeNFT(firstNFT)).to.emit(primaryGun, 'UpgradedNFT').withArgs(firstNFT, 3, 4);
        await expect(primaryGun.connect(admin).upgradeNFT(firstNFT)).to.emit(primaryGun, 'UpgradedNFT').withArgs(firstNFT, 3, 5);
        await expect(primaryGun.connect(admin).upgradeNFT(firstNFT)).to.be.revertedWith('Blue and Purple rarity NFT have max level Five');
    });

    it('Transfer to other address', async () => {
        await primaryGun.connect(admin).createNew(1, randomUser1.address);
        const firstNFT = await primaryGun.connect(admin).totalSupply();

        await primaryGun.connect(randomUser1).approve(admin.address, firstNFT);
        await primaryGun.connect(admin)['safeTransferFrom(address,address,uint256)'](randomUser1.address, admin.address, firstNFT);
        expect(await primaryGun.connect(admin).ownerOf(firstNFT)).eq(admin.address);
    });
});
