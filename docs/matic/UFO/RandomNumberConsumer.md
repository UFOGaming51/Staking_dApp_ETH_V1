## `RandomNumberConsumer`

Chainlink VRF consumer. The contract must contain some LINK tokens against it for random number to be fetched from VRF



### `onlyVerifiedConsumer(address _consumer)`

Lets the functions to be only called by a verified consumer





### `constructor(address owner)` (public)

The keyhash, VRF co-ordinator address and link token address will change as per network


-----


### `getRandomNumber() → bytes32 requestId` (external)

Generate a random number




### `fulfillRandomness(bytes32, uint256 randomness)` (internal)

Fullfill randomness



### `addVerifierConsumer(address _consumer)` (external)

Add a verified consumer. Only verified consumers can fetch the random number from the contract




### `removeConsumer(address _consumer)` (external)

Removes consumer




### `withdrawLink()` (external)








