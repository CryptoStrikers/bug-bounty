pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "./StrikersChecklist.sol";

/// @title Base contract for CryptoStrikers. Defines what a card is and how to mint one.
/// @author The CryptoStrikers Team
contract StrikersBase is ERC721Token("CryptoStrikers", "STRK") {

  /// @dev Emit this event whenever we mint a new card (see _mintCard below)
  event CardMinted(uint256 cardId);

  /// @dev The struct representing the game's main object, a sports trading card.
  struct Card {
    // The timestamp at which this card was minted.
    uint64 mintTime;

    // The checklist item represented by this card. See StrikersChecklist.sol for more info.
    uint8 checklistId;

    // Cards for a given player have a serial number, which gets
    // incremented in sequence. If we mint 1000 Messis, the third one
    // to be minted has serialNumber = 3 (out of 1000, for example).
    uint16 serialNumber;
  }

  /*** STORAGE ***/

  /// @dev All the cards that have been minted, indexed by cardId.
  Card[] public cards;

  /// @dev Keeps track of how many cards we have minted for a given checklist ID
  ///   to make sure we don't go over the limit for that checklistItem.
  mapping (uint8 => uint16) public mintedCountForChecklistId;

  /// @dev A reference to our checklist contract, which contains all the minting limits.
  StrikersChecklist public strikersChecklist;

  /*** FUNCTIONS ***/

  /// @dev For a given owner, returns two arrays. The first contains the IDs of every card owned
  ///   by this address. The second returns the corresponding checklist ID for each of these cards.
  ///   There are a few places we need this info in the web app and short of being able to return an
  ///   actual array of Cards, this is the best solution we could come up with...
  function cardAndChecklistIdsForOwner(address _owner) external view returns (uint256[], uint8[]) {
    uint256[] memory cardIds = ownedTokens[_owner];
    uint256 cardCount = cardIds.length;
    uint8[] memory checklistIds = new uint8[](cardCount);

    for (uint256 i = 0; i < cardCount; i++) {
      uint256 cardId = cardIds[i];
      checklistIds[i] = cards[cardId].checklistId;
    }

    return (cardIds, checklistIds);
  }

  /// @dev An internal method that creates a new card and stores it.
  ///  Emits both a CardMinted and a Transfer event.
  /// @param _checklistId The ID of the checklistItem represented by the card (see Checklist.sol)
  /// @param _owner The card's first owner!
  function _mintCard(
    uint8 _checklistId,
    address _owner
  )
    internal
    returns (uint256)
  {
    uint16 mintLimit = strikersChecklist.limitForChecklistId(_checklistId);
    require(mintLimit == 0 || mintedCountForChecklistId[_checklistId] < mintLimit, "Can't mint any more of this card!");
    uint16 serialNumber = ++mintedCountForChecklistId[_checklistId];
    Card memory newCard = Card({
      mintTime: uint64(now),
      checklistId: _checklistId,
      serialNumber: serialNumber
    });
    uint256 newCardId = cards.push(newCard) - 1;
    emit CardMinted(newCardId);
    _mint(_owner, newCardId);
    return newCardId;
  }
}
