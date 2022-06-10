import { BigNumberish, BytesLike, Signer } from 'ethers';
import {
    PrimaryGun,
    SecondaryGun,
    Flex,
    ModuleAbil,
    ModuleAgil,
    ModuleDef,
    Drone,
    Melee,
    RobotPassive1,
    RobotPassive2,
    RobotPassive3,
    RobotAbility1,
    RobotAbility2,
    RobotAbilityMelee,
    UFO,
} from '../../typechain';

import {
    PrimaryGun__factory,
    SecondaryGun__factory,
    Flex__factory,
    ModuleAbil__factory,
    ModuleAgil__factory,
    ModuleDef__factory,
    Drone__factory,
    Melee__factory,
    RobotPassive1__factory,
    RobotPassive2__factory,
    RobotPassive3__factory,
    RobotAbility1__factory,
    RobotAbility2__factory,
    RobotAbilityMelee__factory,
    UFO__factory,
} from '../../typechain';

import { Address } from 'hardhat-deploy/dist/types';

export default class DeployNFTContracts {
    private _deployerSigner: Signer;

    constructor(deployerSigner: Signer) {
        this._deployerSigner = deployerSigner;
    }

    public async deployPrimaryGun(): Promise<PrimaryGun> {
        return await new PrimaryGun__factory(this._deployerSigner).deploy();
    }

    public async getPrimaryGun(contractAddress: Address): Promise<PrimaryGun> {
        return new PrimaryGun__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deploySecondaryGun(): Promise<SecondaryGun> {
        return await new SecondaryGun__factory(this._deployerSigner).deploy();
    }

    public async getSecondaryGun(contractAddress: Address): Promise<SecondaryGun> {
        return new SecondaryGun__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployFlex(): Promise<Flex> {
        return await new Flex__factory(this._deployerSigner).deploy();
    }

    public async getFlex(contractAddress: Address): Promise<Flex> {
        return new Flex__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployModuleAbil(): Promise<ModuleAbil> {
        return await new ModuleAbil__factory(this._deployerSigner).deploy();
    }

    public async getModuleAbil(contractAddress: Address): Promise<ModuleAbil> {
        return new ModuleAbil__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployModuleAgil(): Promise<ModuleAgil> {
        return await new ModuleAgil__factory(this._deployerSigner).deploy();
    }

    public async getModuleAgil(contractAddress: Address): Promise<ModuleAgil> {
        return new ModuleAgil__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployModuleDef(): Promise<ModuleDef> {
        return await new ModuleDef__factory(this._deployerSigner).deploy();
    }

    public async getModuleDef(contractAddress: Address): Promise<ModuleDef> {
        return new ModuleDef__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployDrone(): Promise<Drone> {
        return await new Drone__factory(this._deployerSigner).deploy();
    }

    public async getMelee(contractAddress: Address): Promise<Melee> {
        return new Melee__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployRobotPassive1(): Promise<RobotPassive1> {
        return await new RobotPassive1__factory(this._deployerSigner).deploy();
    }

    public async getRobotPassive1(contractAddress: Address): Promise<RobotPassive1> {
        return new RobotPassive1__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployRobotPassive2(): Promise<RobotPassive2> {
        return await new RobotPassive2__factory(this._deployerSigner).deploy();
    }

    public async getRobotPassive2(contractAddress: Address): Promise<RobotPassive2> {
        return new RobotPassive2__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployRobotPassive3(): Promise<RobotPassive3> {
        return await new RobotPassive3__factory(this._deployerSigner).deploy();
    }

    public async getRobotPassive3(contractAddress: Address): Promise<RobotPassive3> {
        return new RobotPassive3__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployRobotAbility1(): Promise<RobotAbility1> {
        return await new RobotAbility1__factory(this._deployerSigner).deploy();
    }

    public async getRobotAbility1(contractAddress: Address): Promise<RobotAbility1> {
        return new RobotAbility1__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployRobotAbility2(): Promise<RobotAbility2> {
        return await new RobotAbility2__factory(this._deployerSigner).deploy();
    }

    public async getRobotAbility2(contractAddress: Address): Promise<RobotAbility2> {
        return new RobotAbility2__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployRobotAbilityMelee(): Promise<RobotAbilityMelee> {
        return await new RobotAbilityMelee__factory(this._deployerSigner).deploy();
    }

    public async getRobotAbilityMelee(contractAddress: Address): Promise<RobotAbilityMelee> {
        return new RobotAbilityMelee__factory(this._deployerSigner).attach(contractAddress);
    }

    public async deployUFO(): Promise<UFO> {
        return await new UFO__factory(this._deployerSigner).deploy();
    }

    public async getUFO(contractAddress: Address): Promise<UFO> {
        return new UFO__factory(this._deployerSigner).attach(contractAddress);
    }
}
