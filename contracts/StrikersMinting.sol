pragma solidity 0.4.24;

import "./StrikersBase.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

/// @title The contract that exposes minting functions to the outside world and limits who can call them.
/// @author The CryptoStrikers Team
contract StrikersMinting is StrikersBase, Pausable {

  /// @dev Emit this when we decide to no longer mint a given checklist ID.
  event PulledFromCirculation(uint8 checklistId);

  /// @dev If the value for a checklistId is true, we can no longer mint it.
  mapping (uint8 => bool) public outOfCirculation;

  /// @dev The address of the contract that manages the pack sale.
  address public packSaleAddress;

  /// @dev Only the owner can update the address of the pack sale contract.
  /// @param _address The address of the new StrikersPackSale contract.
  function setPackSaleAddress(address _address) external onlyOwner {
    packSaleAddress = _address;
  }

  /// @dev Allows the contract at packSaleAddress to mint cards.
  /// @param _checklistId The checklist item represented by this new card.
  /// @param _owner The card's first owner!
  /// @return The new card's ID.
  function mintPackSaleCard(uint8 _checklistId, address _owner) external returns (uint256) {
    require(msg.sender == packSaleAddress, "Only the pack sale contract can mint here.");
    require(!outOfCirculation[_checklistId], "Can't mint any more of this checklist item...");
    return _mintCard(_checklistId, _owner);
  }

  /// @dev Allows the owner to mint cards from our Unreleased Set.
  /// @param _checklistId The checklist item represented by this new card. Must be >= 200.
  /// @param _owner The card's first owner!
  function mintUnreleasedCard(uint8 _checklistId, address _owner) external onlyOwner {
    require(_checklistId >= 200, "You can only use this to mint unreleased cards.");
    require(!outOfCirculation[_checklistId], "Can't mint any more of this checklist item...");
    _mintCard(_checklistId, _owner);
  }

  /// @dev Allows the owner or the pack sale contract to prevent an Iconic or Unreleased card from ever being minted again.
  /// @param _checklistId The Iconic or Unreleased card we want to remove from circulation.
  function pullFromCirculation(uint8 _checklistId) external {
    bool ownerOrPackSale = (msg.sender == owner) || (msg.sender == packSaleAddress);
    require(ownerOrPackSale, "Only the owner or pack sale can take checklist items out of circulation.");
    require(_checklistId >= 100, "This function is reserved for Iconics and Unreleased sets.");
    outOfCirculation[_checklistId] = true;
    emit PulledFromCirculation(_checklistId);
  }
}
