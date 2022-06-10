## `RareNFT`

RareNFT contract. The contract when inherited gives the gaming related properties to each NFT



### `onlyAdmin()`






### `initialize(address _admin, address _uap, address _ufo)` (public)

Initialize the contract




### `uapRequiredForNextUpgrade(uint256 nftId) → uint256` (public)

Return the number of UAP tokens requried for NFT to upgrade to next Level


The function needs to be updated when further documenation is provided


### `ufoRequiredForNextUpgrade(uint256 nftId) → uint256` (public)

Return the number of UFO tokens required for NFT to upgrade to next level


The function needs to be updated when further documentation is provided


### `getPower(uint256 nftId) → uint256` (public)

Return the power of the given NFT




### `upgradeNFT(uint256 nftId)` (external)

Upgrade A RareNFt




### `_populatepowerTable(enum IRare.Rarity rarity, enum IRare.Level[] levels, uint128[] powers)` (internal)

Populate the power table




### `createNew(enum IRare.Rarity rarity, address _to) → uint256` (external)

Create a new NFT





### `UpgradedNFT(uint256 nftId, enum IRare.Rarity rarity, enum IRare.Level level)`







