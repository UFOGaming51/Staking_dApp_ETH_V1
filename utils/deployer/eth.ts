import { BigNumberish, BytesLike, Signer } from 'ethers';
import { Plasma, UAP } from '../../typechain/';

import { Plasma__factory, UAP__factory } from '../../typechain/';

import { Address } from 'hardhat-deploy/dist/types';

export default class DeployEthContracts {
    private _deployerSigner: Signer;

    constructor(deployerSigner: Signer) {
        this._deployerSigner = deployerSigner;
    }

    public async deployPlasma(name: string, symbol: string, admin: string): Promise<Plasma> {
        return new Plasma__factory(this._deployerSigner).deploy(name, symbol, admin);
    }

    public async getPlasma(plasma: string): Promise<Plasma> {
        return new Plasma__factory(this._deployerSigner).attach(plasma);
    }
}
