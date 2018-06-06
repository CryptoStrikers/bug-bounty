pragma solidity 0.4.24;

import "./StrikersPackFactory.sol";

/// @title All the internal functions that govern the act of turning a uint32 pack into 4 NFTs.
/// @author The CryptoStrikers Team
contract StrikersPackSaleInternal is StrikersPackFactory {

  /// @dev Emit this every time we sell a pack.
  event PackBought(address indexed buyer, uint256[] pack);

  /// @dev The number of cards in a pack.
  uint8 public constant PACK_SIZE = 4;

  /// @dev We increment this nonce when grabbing a random pack in _removeRandomPack().
  uint256 internal randNonce;

  /// @dev Function shared by all 3 ways of buying a pack (ETH, kitty burn, whitelist).
  /// @param _sale The sale we are buying from.
  function _buyPack(PackSale storage _sale) internal whenNotPaused {
    require(msg.sender == tx.origin, "Only EOAs are allowed to buy from the pack sale.");
    require(_sale.packs.length > 0, "The sale has no packs available for sale.");
    uint32 pack = _removeRandomPack(_sale.packs);
    uint256[] memory cards = _mintCards(pack);
    _sale.packsSold++;
    emit PackBought(msg.sender, cards);
  }

  /// @dev Iterates over a uint32 pack 8 bits at a time and turns each group of 8 bits into a token!
  /// @param _pack 32 bit integer where each group of 8 bits represents a checklist ID.
  /// @return An array of 4 token IDs, representing the cards we minted.
  function _mintCards(uint32 _pack) internal returns (uint256[]) {
    uint8 mask = 255;
    uint256[] memory newCards = new uint256[](PACK_SIZE);

    for (uint8 i = 1; i <= PACK_SIZE; i++) {
      // Can't underflow because PACK_SIZE is 4.
      uint8 shift = 32 - (i * 8);
      uint8 checklistId = uint8((_pack >> shift) & mask);
      uint256 cardId = mintingContract.mintPackSaleCard(checklistId, msg.sender);
      newCards[i-1] = cardId;
    }

    return newCards;
  }

  /// @dev Given an array of packs (uint32s), removes one from a random index.
  /// @param _packs The array of uint32s we will be mutating.
  /// @return The random uint32 we removed.
  function _removeRandomPack(uint32[] storage _packs) internal returns (uint32) {
    randNonce++;
    bytes memory packed = abi.encodePacked(now, msg.sender, randNonce);
    uint256 randomIndex = uint256(keccak256(packed)) % _packs.length;
    return _removePackAtIndex(randomIndex, _packs);
  }

  /// @dev Given an array of uint32s, remove the one at a given index and replace it with the last element of the array.
  /// @param _index The index of the pack we want to remove from the array.
  /// @param _packs The array of uint32s we will be mutating.
  /// @return The uint32 we removed from position _index.
  function _removePackAtIndex(uint256 _index, uint32[] storage _packs) internal returns (uint32) {
    // Can't underflow because we do require(_sale.packs.length > 0) in _buyPack().
    uint256 lastIndex = _packs.length - 1;
    require(_index <= lastIndex);
    uint32 pack = _packs[_index];
    _packs[_index] = _packs[lastIndex];
    _packs.length--;
    return pack;
  }
}
