## `UFO`

UFO NFT Contract



### `onlyQuest()`





### `onlyBreeder()`






### `initialize(address _admin, address _uap, address _ufo, address _quest, address _breeder, address _randomNumberConsumer, address _robotAbility1, address _robotAbility2, address _robotPassive1, address _robotPassive2, address _robotPassive3, address _robotAbilityMelee)` (public)

Initializes the UFO NFT contract with dependent parameters




### `createOtherNFT(address receiver) → uint256` (external)

function call to generate a child NFT. Only breeder contract can call




### `_createOtherNFT(address _receiver) → uint256` (internal)

function call to generate a child NFT. Only breeder contract can call




### `_createGenesis() → uint256` (internal)

Create Genesis NFTs




### `onERC721Received(address, address, uint256, bytes) → bytes4` (public)

callback. The logic inside that ensure that only relevant NFTs help



### `getLatestRating(uint256 nftId) → uint256` (public)

The the latest rating of UFO




### `addQuest(uint256 nftId, uint256 questsToAdd)` (external)

Add quest related information to the NFT. Can only be called by quest contract




### `_updatingRating(uint256 nftId, uint256 rating)` (internal)

Internal function to update the rating of the NFT






### `Robot`


uint256 ability1


uint256 ability2


uint256 passive1


uint256 passive2


uint256 passive3


uint256 abilityMelee


string name


uint256 rating


uint256 lastUpdatedAt


bool paused


uint256 pendingUAP



