//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

/**
 * @notice Rating Manager. Manages the UFO rating
 */
contract RatingManager is Initializable {
    address private admin; // admin will be a multisig contract address

    uint256 public ratingDecrementGraceTime;
    uint256 public ratingIncrementPerDay;
    uint256 public ratingDecrementPerDay;

    bool public globalRatingPause;

    uint256 public rating_x;
    uint256 public rating_y;
    uint256 public rating_z;

    uint256 public uap_slab_a;
    uint256 public uap_slab_b;
    uint256 public uap_slab_c;
    uint256 public uap_slab_d;

    uint256[50] private __gap;

    /**
     * @notice Initialize the rating
     * @param _admin Address of the admin
     * @param _ratingDecrementGraceTime Grace Time during which the rating of NFT is not decreased
     * @param _ratingIncrementPerDay Rating increased per day if the UFO is used to complete the quests
     * @param _ratingDecrementPerDay Rating decreased per day if the UFO is not used to played more than grace period
     */
    function RatingManager__Init(
        address _admin,
        uint256 _ratingDecrementGraceTime,
        uint256 _ratingIncrementPerDay,
        uint256 _ratingDecrementPerDay
    ) public initializer {
        admin = _admin;
        ratingDecrementGraceTime = _ratingDecrementGraceTime;
        ratingIncrementPerDay = _ratingIncrementPerDay;
        ratingDecrementPerDay = _ratingDecrementPerDay;

        rating_x = 80000;
        rating_y = 100000;
        rating_z = 120000;

        uap_slab_a = 0;
        uap_slab_b = 5 * (10**18);
        uap_slab_c = 10 * (10**18);
        uap_slab_d = 15 * (10**18);
    }

    /**
     * @notice Get the current rating. (based on time)
     * @param isUfoRatingPaused If the UFO rating is paused
     * @param existingRating last updated rating
     * @param lastUpdated rating last updated at
     */
    function _getRating(
        bool isUfoRatingPaused,
        uint256 existingRating,
        uint256 lastUpdated
    ) internal view returns (uint256) {
        if (globalRatingPause || isUfoRatingPaused) return existingRating;

        uint256 daysSkipedPlaying = (block.timestamp - (lastUpdated)) / (1 days);

        if (daysSkipedPlaying >= ratingDecrementGraceTime) {
            uint256 ratingToDecrease = daysSkipedPlaying * (ratingDecrementPerDay);
            if (ratingToDecrease >= existingRating) {
                return 0;
            } else {
                return existingRating - (ratingToDecrease);
            }
        }
        return existingRating;
    }

    /**
     * @notice Chagne the rating slabs
     * @param x slab C
     * @param y slab Y
     * @param z slab Z
     */
    function changeRatingSlabs(
        uint256 x,
        uint256 y,
        uint256 z
    ) external onlyAdmin {
        require(x > 0, 'x should be greater than 0');
        require(y > x, 'y should be greater than x');
        require(z > y, 'z should be greater than y');

        rating_x = x;
        rating_y = y;
        rating_z = z;
    }

    /**
     * @notice Change the UAP reward slab
     * @param a reward when less than slab X
     * @param b reward when in slab x and slab y
     * @param c reward when in slab y and slab z
     * @param d reward when more than slab z
     */
    function changeUAPRewardsOfSlab(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d
    ) external onlyAdmin {
        uap_slab_a = a;
        uap_slab_b = b;
        uap_slab_c = c;
        uap_slab_d = d;
    }

    /**
     * @notice Returns the amount of UAP to be awarded for given rating
     * @param _rating Rating
     * @return UAP reward
     */
    function getUAPForRating(uint256 _rating) public view returns (uint256) {
        if (_rating <= rating_x) {
            return uap_slab_a;
        } else if (_rating > rating_x && _rating <= rating_y) {
            return uap_slab_b;
        } else if (_rating > rating_y && _rating <= rating_z) {
            return uap_slab_c;
        } else {
            return uap_slab_d;
        }
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
}
