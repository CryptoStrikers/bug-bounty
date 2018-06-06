pragma solidity 0.4.24;

import "./StrikersWhitelist.sol";

/// @title The contract that manages our referral program -- invite your friends and get rewarded!
/// @author The CryptoStrikers Team
contract StrikersReferral is StrikersWhitelist {

  /// @dev A cap for how many free referral packs we are giving away.
  uint16 public constant MAX_FREE_REFERRAL_PACKS = 5000;

  /// @dev The percentage of each sale that gets paid out to the referrer as commission.
  uint256 public constant PERCENT_COMMISSION = 10;

  /// @dev The 8 bonus cards that you get for your first 8 referrals, in order.
  uint8[] public bonusCards = [
    115, // Kanté
    127, // Navas
    122, // Hummels
    130, // Alves
    116, // Cavani
    123, // Özil
    121, // Thiago
    131 // Zlatan
  ];

  /// @dev Emit this event when a sale gets attributed, so the referrer can see a log of all his referrals.
  event SaleAttributed(address indexed referrer, address buyer, uint256 amount);

  /// @dev How much many of the 8 bonus cards this referrer has claimed.
  mapping (address => uint8) public bonusCardsClaimed;

  /// @dev Use this to track whether or not a user has bought at least one pack, to avoid people gaming our referral program.
  mapping (address => uint16) public packsBought;

  /// @dev Keep track of this to make sure we don't go over MAX_FREE_REFERRAL_PACKS.
  uint16 public freeReferralPacksClaimed;

  /// @dev Tracks whether or not a user has already claimed their free referral pack.
  mapping (address => bool) public hasClaimedFreeReferralPack;

  /// @dev How much referral income a given referrer has claimed.
  mapping (address => uint256) public referralCommissionClaimed;

  /// @dev How much referral income a given referrer has earned.
  mapping (address => uint256) public referralCommissionEarned;

  /// @dev Tracks how many sales have been attributed to a given referrer.
  mapping (address => uint16) public referralSaleCount;

  /// @dev A mapping to keep track of who referred a given user.
  mapping (address => address) public referrers;

  /// @dev How much ETH is owed to referrers, so we don't touch it when we withdraw our take from the contract.
  uint256 public totalCommissionOwed;

  /// @dev After a pack is bought with ETH, we call this to attribute the sale to the buyer's referrer.
  /// @param _buyer The user who bought the pack.
  /// @param _amount The price of the pack bought, in wei.
  function _attributeSale(address _buyer, uint256 _amount) internal {
    address referrer = referrers[_buyer];

    // Can only attribute a sale to a valid referrer.
    // Referral commissions only accrue if the referrer has bought a pack.
    if (referrer == address(0) || packsBought[referrer] == 0) {
      return;
    }

    referralSaleCount[referrer]++;

    // The first 8 referral sales each unlock a bonus card.
    // Any sales past the first 8 generate referral commission.
    if (referralSaleCount[referrer] > bonusCards.length) {
      uint256 commission = _amount * PERCENT_COMMISSION / 100;
      totalCommissionOwed += commission;
      referralCommissionEarned[referrer] += commission;
    }

    emit SaleAttributed(referrer, _buyer, _amount);
  }

  /// @dev A referrer calls this to claim the next of the 8 bonus cards he is owed.
  function claimBonusCard() external {
    uint16 attributedSales = referralSaleCount[msg.sender];
    uint8 cardsClaimed = bonusCardsClaimed[msg.sender];
    require(attributedSales > cardsClaimed, "You have no unclaimed bonus cards.");
    require(cardsClaimed < bonusCards.length, "You have claimed all the bonus cards.");
    bonusCardsClaimed[msg.sender]++;
    uint8 bonusCardChecklistId = bonusCards[cardsClaimed];
    mintingContract.mintPackSaleCard(bonusCardChecklistId, msg.sender);
  }

  /// @dev A user who was referred to CryptoStrikers can call this once to claim their free pack (must have bought a pack first).
  function claimFreeReferralPack() external {
    address referrer = referrers[msg.sender];
    require(referrer != address(0), "You haven't attributed your referrer using buyFirstPackFromReferral().");
    require(packsBought[referrer] > 0, "To avoid abuse, the person who referred you must also have bought a pack.");
    require(!hasClaimedFreeReferralPack[msg.sender], "You have already claimed your free referral pack!");
    require(freeReferralPacksClaimed < MAX_FREE_REFERRAL_PACKS, "We've already given away all the free referral packs...");
    freeReferralPacksClaimed++;
    hasClaimedFreeReferralPack[msg.sender] = true;
    _buyPack(standardSale);
  }

  /// @dev Allows the contract owner to manually set the referrer for a given user, in case this wasn't properly attributed.
  /// @param _for The user we want to set the referrer for.
  /// @param _referrer The user who will now get credit for _for's future purchases.
  function setReferrer(address _for, address _referrer) external onlyOwner {
    referrers[_for] = _referrer;
  }

  /// @dev Allows a user to withdraw the referral commission they are owed.
  function withdrawCommission() external {
    uint256 commission = referralCommissionEarned[msg.sender] - referralCommissionClaimed[msg.sender];
    require(commission > 0, "You are not owed any referral commission.");
    totalCommissionOwed -= commission;
    referralCommissionClaimed[msg.sender] += commission;
    msg.sender.transfer(commission);
  }
}
