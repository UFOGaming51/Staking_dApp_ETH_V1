import { BigNumberish, BytesLike, Signer } from 'ethers';

import {
    XToken,
    ERC20,
    IUniswapV2Factory,
    IUniswapV2Pair,
    IUniswapV2Router02,
    Quest,
    Breeder,
    RandomNumberConsumer,
    StakingFactory,
    MockRootChainManager,
    Staking,
    CustomBridge,
    Beacon,
    DepositHelper,
} from '../../typechain/';

import {
    XToken__factory,
    ERC20__factory,
    IUniswapV2Factory__factory,
    IUniswapV2Pair__factory,
    IUniswapV2Router02__factory,
    TransparentUpgradeableProxy,
    TransparentUpgradeableProxy__factory,
    Quest__factory,
    Breeder__factory,
    RandomNumberConsumer__factory,
    StakingFactory__factory,
    MockRootChainManager__factory,
    CustomBridge__factory,
    Staking__factory,
    Beacon__factory,
    DepositHelper__factory,
} from '../../typechain/';

import { IlockTokens } from '../../typechain/IlockTokens';
import { IlockTokens__factory } from '../../typechain/factories/IlockTokens__factory';

import { Address } from 'hardhat-deploy/dist/types';

export default class DeployHelperContracts {
    private _deployerSigner: Signer;

    constructor(deployerSigner: Signer) {
        this._deployerSigner = deployerSigner;
    }

    public async getIlockToken(contractAddress: Address): Promise<IlockTokens> {
        return await IlockTokens__factory.connect(contractAddress, this._deployerSigner);
    }

    public async getUniswapV2Router02(uniswapV2Router02: Address): Promise<IUniswapV2Router02> {
        return await IUniswapV2Router02__factory.connect(uniswapV2Router02, this._deployerSigner);
    }

    public async getUniswapV2Factory(uniswapV2Factory: Address): Promise<IUniswapV2Factory> {
        return await IUniswapV2Factory__factory.connect(uniswapV2Factory, this._deployerSigner);
    }

    public async getUniswapV2Pair(uniswapV2Pair: Address): Promise<IUniswapV2Pair> {
        return await IUniswapV2Pair__factory.connect(uniswapV2Pair, this._deployerSigner);
    }

    public async getMockERC20(tokenAddress: Address): Promise<ERC20> {
        return await new ERC20__factory(this._deployerSigner).attach(tokenAddress);
    }

    public async deployXToken(name: string, symbol: string, init_supply: BigNumberish, minter: string): Promise<XToken> {
        return await new XToken__factory(this._deployerSigner).deploy(name, symbol, init_supply, minter);
    }

    public async getXToken(tokenAddress: Address): Promise<XToken> {
        return new XToken__factory(this._deployerSigner).attach(tokenAddress);
    }

    public async deployTransparentUpgradableProxy(logic: string, admin: string): Promise<TransparentUpgradeableProxy> {
        return new TransparentUpgradeableProxy__factory(this._deployerSigner).deploy(logic, admin, '0x');
    }

    public async getTransparentUpgradableProxy(proxyAddress: string): Promise<TransparentUpgradeableProxy> {
        return new TransparentUpgradeableProxy__factory(this._deployerSigner).attach(proxyAddress);
    }

    public async deployQuest(): Promise<Quest> {
        return await new Quest__factory(this._deployerSigner).deploy();
    }

    public async getQuest(contractAddress: string): Promise<Quest> {
        return new Quest__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployBreeder(): Promise<Breeder> {
        return await new Breeder__factory(this._deployerSigner).deploy();
    }

    public async getBreeder(contractAddress: Address): Promise<Breeder> {
        return new Breeder__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployRandomumberConsumer(
        owner: Address,
        vrfCoordinator: Address,
        linkToken: Address,
        keyHash: BytesLike
    ): Promise<RandomNumberConsumer> {
        return await new RandomNumberConsumer__factory(this._deployerSigner).deploy(owner, vrfCoordinator, linkToken, keyHash);
    }

    public async getRandomNumberConsumer(contractAddress: string): Promise<RandomNumberConsumer> {
        return new RandomNumberConsumer__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployStakingFactory(
        beacon: string,
        admin: string,
        ufoRewardsForUfoPools: BigNumberish,
        ufoRewardForULpPools: BigNumberish,
        rewardToken: string,
        ufoToken: string,
        lpToken: string
    ): Promise<StakingFactory> {
        let sf = new StakingFactory__factory(this._deployerSigner).deploy(
            beacon,
            admin,
            ufoRewardsForUfoPools,
            ufoRewardForULpPools,
            rewardToken,
            ufoToken,
            lpToken
        );
        return (await sf).deployed();
    }

    public async getStakingFactory(contractAddress: string): Promise<StakingFactory> {
        return new StakingFactory__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployMockRootChainManager(): Promise<MockRootChainManager> {
        return new MockRootChainManager__factory(this._deployerSigner).deploy();
    }

    public async getMockRootChainManager(contractAddress: string): Promise<MockRootChainManager> {
        return new MockRootChainManager__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployStaking(plasmaToken: string, erc20Predicate: string, maticBridge: string): Promise<Staking> {
        return (await new Staking__factory(this._deployerSigner).deploy(plasmaToken, erc20Predicate, maticBridge)).deployed();
    }

    public async getStaking(contractAddress: string): Promise<Staking> {
        return new Staking__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployCustomBridge(erc20Predicate: string, maticBridge: string, plasmaToken: string): Promise<CustomBridge> {
        return (await new CustomBridge__factory(this._deployerSigner).deploy(erc20Predicate, maticBridge, plasmaToken)).deployed();
    }

    public async getCustomBridhe(address: string): Promise<CustomBridge> {
        return new CustomBridge__factory(this._deployerSigner).attach(address);
    }

    public async deployBeacon(owner: string, implementation: string): Promise<Beacon> {
        return await (await new Beacon__factory(this._deployerSigner).deploy(owner, implementation)).deployed();
    }

    public async getBeacon(contractAddress: string): Promise<Beacon> {
        return new Beacon__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployDepositHelper(
        allUfoPools: string[],
        allLpPools: string[],
        ufoToken: string,
        lpToken: string
    ): Promise<DepositHelper> {
        return await (await new DepositHelper__factory(this._deployerSigner).deploy(allUfoPools, allLpPools, ufoToken, lpToken)).deployed();
    }
}
