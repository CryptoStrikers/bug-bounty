# Basics of CryptoStrikers:

CryptoStrikers is a project that brings beautiful collectible soccer cards to the Ethereum blockchain. Users can buy packs of 4 random cards, swap them with others, and buy/sell individual cards on the marketplace. The game is composed of 4 public facing contracts. Below we'll provide an overview of each.

##### StrikersCore.sol - `0x453659562695ee39bD3Bd9e2AFD3db1BD9901Db3`

Our main, ERC721-compliant contract that brings everything together. It handles card ownership, minting, and peer-to-peer trading.

##### StrikersPackSale.sol - `0x882Df83CC4Ae454Fbe0EF0e6b4F7e270A21bad90`

The contract that allows users to purchase packs of CryptoStrikers cards. Also manages our whitelist and referral programs.

##### StrikersChecklist.sol - `0x77fd1480eb40CB1386aAF7Dca0bed41D705256af`

Governs which players and cards are available in our universe, and enforces scarcity limits.

##### StrikersMetadata.sol - `0x91253D57997abA025fdAe254f6cbe1577A277605`

An upgradeable metadata contract, which right now points to an endpoint that returns JSON conforming to [OpenSea's spec](https://docs.opensea.io/docs/2-adding-metadata).

# Super High Level Stuff

- You can buy packs of 4 cards.
- There are 2 kinds of packs: Standard and Premium.
- Standard Packs contain 4 cards from our Originals set. There are 100 unique card designs in the Originals set.
- Premium Packs have a 1 in 5 chance of featuring an insert from our Iconics set. The remaining cards are filled by Originals (with bronze players removed!). There are 32 unique card designs in the Iconics set.
- The player featured in Premium packs is rotated on a daily basis throughout the tournament (match days only, 24 days total).
- Each Premium sale is limited to 500 packs, which means that the Iconics insert for that day is limited to 100 cards.
- You can create peer-to-peer trades by signing a message off-chain and then having another user settle it on-chain.
- If you refer your friends and they buy packs, you can unlock exclusive Iconics cards (for your first 8 attributed sales) and then collect 10% commission on all sales thereafter.
- You can sell the cards you own or seek out players you're missing on OpenSea's marketplace.
- Collect all 100 Originals and all 32 Iconics to win special prizes.

# Deployment Flow

Here are the deploy steps that the contract owner will undertake:

1. Deploy `StrikersChecklist.sol`.
1. On the `StrikersChecklist` contract, call `deployStepOne()` through `deployStepFour()`, in order. This deploy needs to happen in multiple steps given the amount of data we are storing in the contract.
1. Deploy `StrikersCore.sol` with `StrikersChecklist`'s address as a constructor argument.
1. Deploy `StrikersPackSale.sol` with 3 constructor arguments: the price for a Standard pack (in wei), the address of the CryptoKitties contract (so we can burn kitties in exchange for packs), and the address of `StrikersCore` (so the PackSale contract can mint cards).
1. Call `setPackSaleAddress()` on `StrikersCore`.
1. Deploy `StrikersMetadata` and then call `setMetadataContract` on `StrikersCore`.


# Expected Usage Flow

Here's how we expect the smart contracts will be used:

1. `StrikersPackSale` starts off as paused, so owner first calls `addPacksToStandardSale()` and adds some packs to the sale.
1. Once the packs have been loaded, call `startStandardSale()`, which unpauses `StrikersPackSale`.
1. The owner can keep adding packs to the sale (up to `MAX_STANDARD_SALE_PACKS`), always using `addPacksToStandardSale()`.
1. The owner can also change the price of packs (to reflect fluctuations in the price of ETH) by calling `setStandardPackPrice()`.
1. For Premium packs, the flow goes: `createNextPremiumSale()` -> `addPacksToNextPremiumSale()` -> (optional) `modifyNextPremiumSale()` -> `startNextPremiumSale()`. This flow can be repeated up to 24 times, which is the max # of Premium sales we are allowed to run (each sale = 500 packs).
1. Now that the contract has some packs for sale, users can acquire packs using the following methods: `buyPackWithETH()`, or `buyPackWithKitty()` (burn capped at 1000 cats).
1. If a user came to the app from a referral, when they buy their first pack, they instead call `buyFirstPackFromReferral()` with the address of the user who referred them.
1. This referred user will then be able to claim a free pack by calling `claimFreeReferralPack()` (capped at 1000 free packs).
1. Going forward, every pack they buy gets attributed to their referrer, who can claim his/her referral bonuses using `claimBonusCard()` (first 8 attributed sales) and `withdrawCommission()` (10% commission on every sale thereafter).
1. At any time, the owner can grant free packs to a user by adding them to one of two whitelists found in `StrikersWhitelist`. To do this, we call either `addToWhitelistAllocation()` (single address) or `addAddressesToWhitelist()` (bulk).
1. A whitelisted user can then call `claimWhitelistPack()` on `StrikersWhitelist` to get the free pack they are owed.
1. A card owner can create a trade, sign it off-chain, and share that signed trade with other users. A user can then fill that trade by calling `fillTrade()` on `StrikersTrading` to execute the swap.
1. The trade creator can invalidate a trade he has already signed by calling `cancelTrade()`, also on `StrikersTrading`.
1. If, during the course of the tournament, we want to add more players to the game, we call `addPlayer()` on `StrikersChecklist`.
1. We can then add a checklist item for this player to our Unreleased Set by calling `addUnreleasedChecklistItem()` on `StrikersChecklist`.
1. If we want to then mint cards for that checklist item, we can call `mintUnreleasedCard()` on `StrikersCore`.
1. To take a given checklist item out of circulation and prevent it from ever being minted again, we can call `pullFromCirculation()` on `StrikersCore`.
1. To withdraw the ETH earned from selling packs (minus commission owed to referrers), the owner calls `withdrawBalance()` on `StrikersPackSale`.

We've tried our best to make sure our code is clear and well-commented. Please check the source if you have any questions, and feel free to ping us on [Discord](https://discord.gg/nQUy3Pc).
