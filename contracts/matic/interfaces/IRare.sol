//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @notice Rare NFT properties
 */
interface IRare {
    enum Rarity {
        White,
        Green,
        Blue,
        Purple
    }

    enum Level {
        Zero,
        One,
        Two,
        Three,
        Four,
        Five
    }

    struct NftPowerProperty {
        Rarity rarity;
        Level level;
    }
}
