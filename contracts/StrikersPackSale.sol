pragma solidity 0.4.24;

import "./StrikersReferral.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol";

/// @title The main sale contract, allowing users to purchase packs of CryptoStrikers cards.
/// @author The CryptoStrikers Team
contract StrikersPackSale is StrikersReferral {

  /// @dev The max number of kitties we are allowed to burn.
  uint16 public constant KITTY_BURN_LIMIT = 1000;

  /// @dev Emit this whenever someone sacrifices a cat for a free pack of cards.
  event KittyBurned(address user, uint256 kittyId);

  /// @dev Users are only allowed to burn 1 cat each, so keep track of that here.
  mapping (address => bool) public hasBurnedKitty;

  /// @dev A reference to the CryptoKitties contract so we can transfer cats
  ERC721Basic public kittiesContract;

  /// @dev How many kitties we have burned so far. Think of the cats, make sure we don't go over KITTY_BURN_LIMIT!
  uint16 public totalKittiesBurned;

  /// @dev Keeps track of our sale volume, in wei.
  uint256 public totalWeiRaised;

  /// @dev Constructor. Can't change minting and kitties contracts once they've been initialized.
  constructor(
    uint256 _standardPackPrice,
    address _kittiesContractAddress,
    address _mintingContractAddress
  )
  StrikersPackFactory(_standardPackPrice)
  public
  {
    kittiesContract = ERC721Basic(_kittiesContractAddress);
    mintingContract = StrikersMinting(_mintingContractAddress);
  }

  /// @dev For a user who was referred, use this function to buy your first back so we can attribute the referral.
  /// @param _referrer The user who invited msg.sender to CryptoStrikers.
  /// @param _premium True if we're buying from Premium sale, false if we're buying from Standard sale.
  function buyFirstPackFromReferral(address _referrer, bool _premium) external payable {
    require(packsBought[msg.sender] == 0, "Only assign a referrer on a user's first purchase.");
    referrers[msg.sender] = _referrer;
    buyPackWithETH(_premium);
  }

  /// @dev Allows a user to buy a pack of cards with enough ETH to cover the packPrice.
  /// @param _premium True if we're buying from Premium sale, false if we're buying from Standard sale.
  function buyPackWithETH(bool _premium) public payable {
    PackSale storage sale = _premium ? currentPremiumSale : standardSale;
    uint256 packPrice = sale.packPrice;
    require(msg.value >= packPrice, "Insufficient ETH sent to buy this pack.");
    _buyPack(sale);
    packsBought[msg.sender]++;
    totalWeiRaised += packPrice;
    // Refund excess funds
    msg.sender.transfer(msg.value - packPrice);
    _attributeSale(msg.sender, packPrice);
  }

  /// @notice Magically transform a CryptoKitty into a free pack of cards!
  /// @param _kittyId The cat we are giving up.
  /// @dev Note that the user must first give this contract approval by
  ///   calling approve(address(this), _kittyId) on the CK contract.
  ///   Otherwise, buyPackWithKitty() throws on transferFrom().
  function buyPackWithKitty(uint256 _kittyId) external {
    require(totalKittiesBurned < KITTY_BURN_LIMIT, "Stop! Think of the cats!");
    require(!hasBurnedKitty[msg.sender], "You've already burned a kitty.");
    totalKittiesBurned++;
    hasBurnedKitty[msg.sender] = true;
    // Will throw/revert if this contract hasn't been given approval first.
    // Also, with no way of retrieving kitties from this contract,
    // transferring to "this" burns the cat! (desired behaviour)
    kittiesContract.transferFrom(msg.sender, this, _kittyId);
    _buyPack(standardSale);
    emit KittyBurned(msg.sender, _kittyId);
  }

  /// @dev Allows the contract owner to withdraw the ETH raised from selling packs.
  function withdrawBalance() external onlyOwner {
    uint256 totalBalance = address(this).balance;
    require(totalBalance > totalCommissionOwed, "There is no ETH for the owner to claim.");
    owner.transfer(totalBalance - totalCommissionOwed);
  }
}
