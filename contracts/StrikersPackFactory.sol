pragma solidity 0.4.24;

import "./StrikersMinting.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

/// @title Contract where we create Standard and Premium sales and load them with the packs to sell.
/// @author The CryptoStrikersTeam
contract StrikersPackFactory is Pausable {

  /*** IMPORTANT ***/
  // Given the imperfect nature of on-chain "randomness", we have found that, for this game, the best tradeoff
  // is to generate the PACKS (each containing 4 random CARDS) off-chain and push them to a SALE in the smart
  // contract. Users can then buy a pack, which will be drawn pseudorandomly from the packs we have pre-loaded.
  // It's obviously not perfect, but we think it's a fair tradeoff and tough enough to game, as the packs array is
  // constantly getting re-shuffled as other users buy packs.
  //
  // To save on storage, we use uint32 to represent a pack, with each of the 4 groups of 8 bits representing a checklistId (see Checklist contract).
  // Given that right now we only have 132 checklist items (with the plan to maybe add a few more during the tournament),
  // uint8 is fine (max uint8 is 255...)
  //
  // For example:
  // Pack = 00011000000001100000001000010010
  // Card 1 = 00011000 = checklistId 24
  // Card 2 = 00000110 = checklistId 6
  // Card 3 = 00000010 = checklistId 2
  // Card 4 = 00010010 = checklistId 18
  //
  // Then, when a user buys a pack, he actually mints 4 NFTs, each corresponding to one of those checklistIds (see StrikersPackSale contract).
  //
  // In testing, we were only able to load ~500 packs (recall: each a uint32) per transaction before hititng the block gas limit,
  // which may be less than we need for any given sale, so we load packs in batches. The Standard Sale runs all tournament long, and we
  // will constantly be adding packs to it, up to the limit defined by MAX_STANDARD_SALE_PACKS. As for Premium Sales, we switch over
  // to a new one every day, so while the current one is ongoing, we are able to start prepping the next one using the nextPremiumSale
  // property. We can then load the 500 packs required to start this premium sale in as many transactions as we want, before pushing it
  // live.

  /*** EVENTS ***/

  /// @dev Emit this event each time we load packs for a given sale.
  event PacksLoaded(uint8 indexed saleId, uint32[] packs);

  /// @dev Emit this event when the owner starts a sale.
  event SaleStarted(uint8 saleId, uint256 packPrice, uint8 featuredChecklistItem);

  /// @dev Emit this event when the owner changes the standard sale's packPrice.
  event StandardPackPriceChanged(uint256 packPrice);

  /*** CONSTANTS ***/

  /// @dev Our Standard sale runs all tournament long but has a hard cap of 75,616 packs.
  uint32 public constant MAX_STANDARD_SALE_PACKS = 75616;

  /// @dev Each Premium sale will contain exactly 500 packs.
  uint16 public constant PREMIUM_SALE_PACK_COUNT = 500;

  /// @dev We can only run a total of 24 Premium sales.
  uint8 public constant MAX_NUMBER_OF_PREMIUM_SALES = 24;

  /*** DATA TYPES ***/

  /// @dev The struct representing a PackSale from which packs are dispensed.
  struct PackSale {
    // A unique identifier for this sale. Based on saleCount at the time of this sale's creation.
    uint8 id;

    // The card of the day, if it's a Premium sale. Once that sale ends, we can never mint this card again.
    uint8 featuredChecklistItem;

    // The price, in wei, for 1 pack of cards. The only case where this is 0 is when the struct is null, so
    // we use it as a null check.
    uint256 packPrice;

    // All the packs we have loaded for this sale. Max 500 for each Premium sale, and 75,616 for the Standard sale.
    uint32[] packs;

    // The number of packs loaded so far in this sale. Because people will be buying from the Standard sale as
    // we keep loading packs in, we need this counter to make sure we don't go over MAX_STANDARD_SALE_PACKS.
    uint32 packsLoaded;

    // The number of packs sold so far in this sale.
    uint32 packsSold;
  }

  /*** STORAGE ***/

  /// @dev A reference to the core contract, where the cards are actually minted.
  StrikersMinting public mintingContract;

  /// @dev Our one and only Standard sale, which runs all tournament long.
  PackSale public standardSale;

  /// @dev The Premium sale that users are currently able to buy from.
  PackSale public currentPremiumSale;

  /// @dev We stage the next Premium sale here before we push it live with startNextPremiumSale().
  PackSale public nextPremiumSale;

  /// @dev How many sales we've ran so far. Max is 25 (1 Standard + 24 Premium).
  uint8 public saleCount;

  /*** MODIFIERS  ***/

  modifier nonZeroPackPrice(uint256 _packPrice) {
    require(_packPrice > 0, "Free packs are only available through the whitelist.");
    _;
  }

  /*** CONSTRUCTOR ***/

  constructor(uint256 _packPrice) public {
    // Start contract in paused state so we have can go and load some packs in.
    paused = true;
    // Init Standard sale. (all properties default to 0, except packPrice, which we set here)
    setStandardPackPrice(_packPrice);
    saleCount++;
  }

  /*** SHARED FUNCTIONS (STANDARD & PREMIUM) ***/

  /// @dev Internal function to push a bunch of packs to a PackSale's packs array.
  /// @param _newPacks An array of 32 bit integers, each representing a shuffled pack.
  /// @param _sale The PackSale we are pushing to.
  function _addPacksToSale(uint32[] _newPacks, PackSale storage _sale) internal {
    for (uint256 i = 0; i < _newPacks.length; i++) {
      _sale.packs.push(_newPacks[i]);
    }
    _sale.packsLoaded += uint32(_newPacks.length);
    emit PacksLoaded(_sale.id, _newPacks);
  }

  /*** STANDARD SALE FUNCTIONS ***/

  /// @dev Load some shuffled packs into the Standard sale.
  /// @param _newPacks The new packs to load.
  function addPacksToStandardSale(uint32[] _newPacks) external onlyOwner {
    bool tooManyPacks = standardSale.packsLoaded + _newPacks.length > MAX_STANDARD_SALE_PACKS;
    require(!tooManyPacks, "You can't add more than 75,616 packs to the Standard sale.");
    _addPacksToSale(_newPacks, standardSale);
  }

  /// @dev After seeding the Standard sale with a few loads of packs, kick off the sale here.
  function startStandardSale() external onlyOwner {
    require(standardSale.packsLoaded > 0, "You must first load some packs into the Standard sale.");
    unpause();
    emit SaleStarted(standardSale.id, standardSale.packPrice, standardSale.featuredChecklistItem);
  }

  /// @dev Allows us to change the Standard sale pack price while the sale is ongoing, to deal with ETH
  ///   price fluctuations. Premium sale packPrice is set daily (i.e. every time we create a new Premium sale)
  /// @param _packPrice The new Standard pack price, in wei.
  function setStandardPackPrice(uint256 _packPrice) public onlyOwner nonZeroPackPrice(_packPrice) {
    standardSale.packPrice = _packPrice;
    emit StandardPackPriceChanged(_packPrice);
  }

  /*** PREMIUM SALE FUNCTIONS ***/

  /// @dev If nextPremiumSale is null, allows us to create and start setting up the next one.
  /// @param _featuredChecklistItem The card of the day, which we will take out of circulation once the sale ends.
  /// @param _packPrice The price of packs for this sale, in wei. Must be greater than zero.
  function createNextPremiumSale(uint8 _featuredChecklistItem, uint256 _packPrice) external onlyOwner nonZeroPackPrice(_packPrice) {
    require(nextPremiumSale.packPrice == 0, "Next Premium Sale already exists.");
    require(_featuredChecklistItem >= 100, "You can't have an Originals as a featured checklist item.");
    require(saleCount <= MAX_NUMBER_OF_PREMIUM_SALES, "You can only run 24 total Premium sales.");
    nextPremiumSale.id = saleCount;
    nextPremiumSale.featuredChecklistItem = _featuredChecklistItem;
    nextPremiumSale.packPrice = _packPrice;
    saleCount++;
  }

  /// @dev Load some shuffled packs into the next Premium sale that we created.
  /// @param _newPacks The new packs to load.
  function addPacksToNextPremiumSale(uint32[] _newPacks) external onlyOwner {
    require(nextPremiumSale.packPrice > 0, "You must first create a nextPremiumSale.");
    require(nextPremiumSale.packsLoaded + _newPacks.length <= PREMIUM_SALE_PACK_COUNT, "You can't add more than 500 packs to a Premium sale.");
    _addPacksToSale(_newPacks, nextPremiumSale);
  }

  /// @dev Moves the sale we staged in nextPremiumSale over to the currentPremiumSale variable, and clears nextPremiumSale.
  ///   Also removes currentPremiumSale's featuredChecklistItem from circulation.
  function startNextPremiumSale() external onlyOwner {
    require(nextPremiumSale.packsLoaded == PREMIUM_SALE_PACK_COUNT, "You must add exactly 500 packs before starting this Premium sale.");
    if (currentPremiumSale.featuredChecklistItem >= 100) {
      mintingContract.pullFromCirculation(currentPremiumSale.featuredChecklistItem);
    }
    currentPremiumSale = nextPremiumSale;
    delete nextPremiumSale;
  }

  /// @dev Allows the owner to make last second changes to the staged Premium sale before pushing it live.
  /// @param _featuredChecklistItem The card of the day, which we will take out of circulation once the sale ends.
  /// @param _packPrice The price of packs for this sale, in wei. Must be greater than zero.
  function modifyNextPremiumSale(uint8 _featuredChecklistItem, uint256 _packPrice) external onlyOwner nonZeroPackPrice(_packPrice) {
    require(nextPremiumSale.packPrice > 0, "You must first create a nextPremiumSale.");
    nextPremiumSale.featuredChecklistItem = _featuredChecklistItem;
    nextPremiumSale.packPrice = _packPrice;
  }
}
