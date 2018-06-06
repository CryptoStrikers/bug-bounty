pragma solidity 0.4.24;

import "./StrikersPackSaleInternal.sol";

/// @title A contract that manages the whitelist we use for free pack giveaways.
/// @author The CryptoStrikers Team
contract StrikersWhitelist is StrikersPackSaleInternal {

  /// @dev Emit this when the contract owner increases a user's whitelist allocation.
  event WhitelistAllocationIncreased(address indexed user, uint16 amount, bool premium);

  /// @dev Emit this whenever someone gets a pack using their whitelist allocation.
  event WhitelistAllocationUsed(address indexed user, bool premium);

  /// @dev We can only give away a maximum of 1000 Standard packs, and 500 Premium packs.
  uint16[2] public whitelistLimits = [
    1000, // Standard
    500 // Premium
  ];

  /// @dev Keep track of the allocation for each whitelist so we don't go over the limit.
  uint16[2] public currentWhitelistCounts;

  /// @dev Index 0 is the Standard whitelist, index 1 is the Premium whitelist. Maps addresses to free pack allocation.
  mapping (address => uint8)[2] public whitelists;

  /// @dev Allows the owner to allocate free packs (either Standard or Premium) to a given address.
  /// @param _premium True for Premium whitelist, false for Standard whitelist.
  /// @param _addr Address of the user who is getting the free packs.
  /// @param _additionalPacks How many packs we are adding to this user's allocation.
  function addToWhitelistAllocation(bool _premium, address _addr, uint8 _additionalPacks) public onlyOwner {
    uint8 listIndex = _premium ? 1 : 0;
    require(currentWhitelistCounts[listIndex] + _additionalPacks <= whitelistLimits[listIndex]);
    currentWhitelistCounts[listIndex] += _additionalPacks;
    whitelists[listIndex][_addr] += _additionalPacks;
    emit WhitelistAllocationIncreased(_addr, _additionalPacks, _premium);
  }

  /// @dev A way to call addToWhitelistAllocation in bulk. Adds 1 pack to each address.
  /// @param _premium True for Premium whitelist, false for Standard whitelist.
  /// @param _addrs Addresses of the users who are getting the free packs.
  function addAddressesToWhitelist(bool _premium, address[] _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      addToWhitelistAllocation(_premium, _addrs[i], 1);
    }
  }

  /// @dev If msg.sender has whitelist allocation for a given pack type, decrement it and give them a free pack.
  /// @param _premium True for the Premium sale, false for the Standard sale.
  function claimWhitelistPack(bool _premium) external {
    uint8 listIndex = _premium ? 1 : 0;
    require(whitelists[listIndex][msg.sender] > 0, "You have no whitelist allocation.");
    // Can't underflow because of require() check above.
    whitelists[listIndex][msg.sender]--;
    PackSale storage sale = _premium ? currentPremiumSale : standardSale;
    _buyPack(sale);
    emit WhitelistAllocationUsed(msg.sender, _premium);
  }
}
