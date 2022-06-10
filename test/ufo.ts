import { ethers, network } from 'hardhat';
import { expect } from 'chai';

import DeployHelper from '../utils/deployer';
import {
    RobotPassive1,
    RobotPassive2,
    RobotPassive3,
    RobotAbility1,
    RobotAbility2,
    RobotAbilityMelee,
    XToken,
    UAP,
    UFO,
    TransparentUpgradeableProxy,
    RandomNumberConsumer,
    ERC20,
} from '../typechain';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { zeroAddress } from '../utils/constants';
import { BigNumber, BigNumberish } from '@ethersproject/bignumber';

import { mainnet as hardhatConstants } from '../utils/constants';
const { Whale, Contracts } = hardhatConstants;

describe('Robot/UFO', async () => {
    let uapTokenContract: UAP;
    let ufoTokenContract: XToken;

    let robotAbility1: RobotAbility1;
    let robotAbility2: RobotAbility2;
    let robotPassive1: RobotPassive1;
    let robotPassive2: RobotPassive2;
    let robotPassive3: RobotPassive3;
    let robotAbilityMeele: RobotAbilityMelee;

    let ufoNFTContract: UFO;

    let proxyAdmin: SignerWithAddress;
    let admin: SignerWithAddress;
    let randomUser1: SignerWithAddress;
    let randomUser2: SignerWithAddress;
    let randomUser3: SignerWithAddress;
    let minter: SignerWithAddress;

    let randomNumberConsumer: RandomNumberConsumer;
    let LinkWhale: SignerWithAddress;
    let LinkToken: ERC20;

    let snapshotId: any;

    before(async () => {
        await network.provider.request({
            method: 'hardhat_impersonateAccount',
            params: [Whale.LINK],
        });

        LinkWhale = await ethers.getSigner(Whale.LINK);
        let deployHelper0 = new DeployHelper(LinkWhale);
        LinkToken = await deployHelper0.helper.getMockERC20(Contracts.LINK);

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

        ufoTokenContract = await deployHelper.helper.deployXToken('UFO', 'UFO', BigNumber.from('0'), admin.address);
        await ufoTokenContract.connect(admin).mint(admin.address, '1000000000000004534300000');

        let robotAbility1Logic: RobotAbility1 = await deployHelper.nft.deployRobotAbility1();
        let robotAbility2Logic: RobotAbility2 = await deployHelper.nft.deployRobotAbility2();
        let robotPassive1Logic: RobotPassive1 = await deployHelper.nft.deployRobotPassive1();
        let robotPassive2Logic: RobotPassive2 = await deployHelper.nft.deployRobotPassive2();
        let robotPassive3Logic: RobotPassive3 = await deployHelper.nft.deployRobotPassive3();
        let robotAbilityMeleeLogic: RobotAbilityMelee = await deployHelper.nft.deployRobotAbilityMelee();

        proxy = await deployHelper.helper.deployTransparentUpgradableProxy(robotAbility1Logic.address, proxyAdmin.address);
        robotAbility1 = await deployHelper.nft.getRobotAbility1(proxy.address);
        proxy = await deployHelper.helper.deployTransparentUpgradableProxy(robotAbility2Logic.address, proxyAdmin.address);
        robotAbility2 = await deployHelper.nft.getRobotAbility2(proxy.address);
        proxy = await deployHelper.helper.deployTransparentUpgradableProxy(robotPassive1Logic.address, proxyAdmin.address);
        robotPassive1 = await deployHelper.nft.getRobotPassive1(proxy.address);
        proxy = await deployHelper.helper.deployTransparentUpgradableProxy(robotPassive2Logic.address, proxyAdmin.address);
        robotPassive2 = await deployHelper.nft.getRobotPassive2(proxy.address);
        proxy = await deployHelper.helper.deployTransparentUpgradableProxy(robotPassive3Logic.address, proxyAdmin.address);
        robotPassive3 = await deployHelper.nft.getRobotPassive3(proxy.address);
        proxy = await deployHelper.helper.deployTransparentUpgradableProxy(robotAbilityMeleeLogic.address, proxyAdmin.address);
        robotAbilityMeele = await deployHelper.nft.getRobotAbilityMelee(proxy.address);

        let ufoNftContractLogic: UFO = await deployHelper.nft.deployUFO();
        proxy = await deployHelper.helper.deployTransparentUpgradableProxy(ufoNftContractLogic.address, proxyAdmin.address);
        ufoNFTContract = await deployHelper.nft.getUFO(proxy.address);

        await robotAbility1.connect(admin).initialize(ufoNFTContract.address, uapTokenContract.address, ufoTokenContract.address);
        await robotAbility2.connect(admin).initialize(ufoNFTContract.address, uapTokenContract.address, ufoTokenContract.address);
        await robotPassive1.connect(admin).initialize(ufoNFTContract.address, uapTokenContract.address, ufoTokenContract.address);
        await robotPassive2.connect(admin).initialize(ufoNFTContract.address, uapTokenContract.address, ufoTokenContract.address);
        await robotPassive3.connect(admin).initialize(ufoNFTContract.address, uapTokenContract.address, ufoTokenContract.address);
        await robotAbilityMeele.connect(admin).initialize(ufoNFTContract.address, uapTokenContract.address, ufoTokenContract.address);

        randomNumberConsumer = await deployHelper.helper.deployRandomumberConsumer(
            admin.address,
            '0xf0d54349aDdcf704F77AE15b96510dEA15cb7952',
            '0x514910771AF9Ca656af840dff83E8264EcF986CA',
            '0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445'
        );

        await randomNumberConsumer.connect(admin).addVerifierConsumer(ufoNFTContract.address);

        console.log({ randomNumberConsumer: randomNumberConsumer.address });
        await LinkToken.transfer(randomNumberConsumer.address, BigNumber.from(5).mul(BigNumber.from(10).pow(18)));

        await ufoNFTContract.connect(admin).initialize(
            admin.address,
            uapTokenContract.address,
            ufoTokenContract.address,
            randomUser1.address, // temp quest address
            randomUser2.address, // temp breeder address
            randomNumberConsumer.address,
            robotAbility1.address,
            robotAbility2.address,
            robotPassive1.address,
            robotPassive2.address,
            robotPassive3.address,
            robotAbilityMeele.address
        );
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

    // TODO: @Akshay
    // it('Check if 9 genesis NFTs are minted', async () => {
    //     expect(await ufoNFTContract.connect(admin).totalSupply()).eq(9);
    // });
});
