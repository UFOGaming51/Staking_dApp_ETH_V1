import { BigNumberish, BytesLike, Signer } from 'ethers';
import { Plasma, UAP } from '../../typechain/';

import { Plasma__factory, UAP__factory } from '../../typechain/';

import { Address } from 'hardhat-deploy/dist/types';

export default class DeployMaticContracts {
    private _deployerSigner: Signer;

    constructor(deployerSigner: Signer) {
        this._deployerSigner = deployerSigner;
    }

    public async deployUAP(): Promise<UAP> {
        return await new UAP__factory(this._deployerSigner).deploy();
    }

    public async getUAP(tokenAddress: Address): Promise<UAP> {
        return new UAP__factory(this._deployerSigner).attach(tokenAddress);
    }
}
