import { Signer } from 'ethers';

import DeployEthContracts from './eth';
import DeployHelperContracts from './helper';
import DeployMaticContracts from './matic';
import DeployNFTContracts from './nft';

export default class DeployHelper {
    public helper: DeployHelperContracts;
    public matic: DeployMaticContracts;
    public nft: DeployNFTContracts;
    public eth: DeployEthContracts;

    constructor(deployerSigner: Signer) {
        this.helper = new DeployHelperContracts(deployerSigner);
        this.matic = new DeployMaticContracts(deployerSigner);
        this.nft = new DeployNFTContracts(deployerSigner);
        this.eth = new DeployEthContracts(deployerSigner);
    }
}
