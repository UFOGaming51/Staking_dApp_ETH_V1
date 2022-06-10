# UFO-Contracts

Smart contracts for UFO.

use `node 12.14.1` or greater

1. Install the required node modules
   `yarn install --dev`
2. Generated the required artifacts `yarn build`
3. Test the contract. (by default mainnet fork is used) `yarn test`

To deploy the contracts

`npx hardhat run ./matic_scripts/zz_deployUfoAndUfoData.ts --network matic_mumbai`
Change the network for relevant network
Ensure that private keys are set in .env file along with the right configuration in the hardhat.config.ts