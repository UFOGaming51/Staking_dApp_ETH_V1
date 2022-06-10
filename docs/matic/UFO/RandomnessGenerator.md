## `RandomnessGenerator`

Random number generator




### `RandomnessGenerator__init(uint256 _maxRatingAtInit, address _randomNumberConsumer)` (public)

Initialize Randomness generator contract




### `_getRandomRating(uint256 randomizer) → uint256` (internal)

Generate a random rating




### `_getRandomness(uint256 randomizer) → uint256` (internal)

Generate randomness that can be used by any




### `_generateName(uint256 randomizer) → string` (internal)

Generate Name




### `concat(string _self, string _other) → string` (internal)

Concat to strings


Can be optimized by using abi.encode(args);


### `toSlice(string self) → struct RandomnessGenerator.slice` (internal)

Create struct for string operation


Its use can be avoided if abi.encode(arg) is used


### `memcpy(uint256 dest, uint256 src, uint256 len)` (internal)







### `slice`


uint256 _len


uint256 _ptr



