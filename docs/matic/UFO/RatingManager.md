## `RatingManager`

Rating Manager. Manages the UFO rating



### `onlyAdmin()`






### `RatingManager__Init(address _admin, uint256 _ratingDecrementGraceTime, uint256 _ratingIncrementPerDay, uint256 _ratingDecrementPerDay)` (public)

Initialize the rating




### `_getRating(bool isUfoRatingPaused, uint256 existingRating, uint256 lastUpdated) → uint256` (internal)

Get the current rating. (based on time)




### `changeRatingSlabs(uint256 x, uint256 y, uint256 z)` (external)

Chagne the rating slabs




### `changeUAPRewardsOfSlab(uint256 a, uint256 b, uint256 c, uint256 d)` (external)

Change the UAP reward slab




### `getUAPForRating(uint256 _rating) → uint256` (public)

Returns the amount of UAP to be awarded for given rating







