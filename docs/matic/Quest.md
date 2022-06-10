## `Quest`

Quest Contract



### `onlyGameServer()`






### `initialize(address _ufoNFT, address _admin, address _gameServer, uint256 _maxQuestsPerDay)` (public)

Initialize the Quest Contract




### `_canAddQuestToUFO(uint256 nftd, bytes32 questId) → bool` (internal)

Checks whether the given quests can be added to the UFO




### `registerQuestsAndUpdateUFO(uint256[] nftIds, bytes32[][] quests)` (external)

Registers the quests and updates the UFO and its rewards. The function can be called only by the gameserver


Modify the function to use multi-call to reduce the transaction cost

### `_updateQuestSingleUfo(uint256 nftId, bytes32[] quests)` (internal)

Internal function to update the quests for a single NFT







