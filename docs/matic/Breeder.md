## `Breeder`

Breeder Contract



### `onlyAdmin()`






### `initialize(address _admin, address _ufoNTF, address _ufoToken, address _uapToken)` (public)

Initialize the Breeder contract




### `changeAdmin(address _admin)` (external)

Change Admin address


Use OwnableUpgradable contract and replace this


### `changeLockTimeDays(uint256 newLockTime)` (external)

Change the locktime for NFT Breeding




### `setUfoContract(address _ufoContract)` (external)

Set The UFO NFT contract




### `lockUFOsForBreeding(uint256 ufo1, uint256 ufo2, address _receiver)` (external)

Lock the NFT tokens for breeding




### `getChildUfo(uint256 breedingCellNumber)` (external)

Complete the ownsership transfer for child NFT




### `releaseUfoWithoutBreeding(uint256 breedingCellNumber)` (external)

Release the NFT without breeding. If breeding ritual needs to be called in the middle




### `ufoRequiredForBreeding() → uint256` (public)

Returns the number of UFO for breeding


The function needs to be written once the specs are provided

### `uapRequiredForBreeding() → uint256` (public)

Returns the number of UAP for breeding


The function needs to be written once the specs are provided

### `onERC721Received(address, address, uint256, bytes) → bytes4` (public)

callback. The logic inside that ensure that only relevant NFTs help




### `ChangeLockTime(uint256 newLockTime)`





### `StartBreeding(uint256 ufo1, uint256 ufo2, uint256 releaseTime)`





### `CancelBreeding(uint256 breedingCellNumber, uint256 ufo1, uint256 ufo2)`





### `CompleteBreeding(uint256 breedingCellNumber, uint256 ufo1, uint256 ufo2)`






### `BreedingCell`


uint256 ufo1


uint256 ufo2


uint256 unlockTime


address receiver


address requestCreator


uint256 ufoTokenRequired


uint256 uapTokenRequired



