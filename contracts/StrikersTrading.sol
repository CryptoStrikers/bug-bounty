pragma solidity ^0.4.24;

import "./StrikersMinting.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

/// @title StrikersTrading - Allows users to trustlessly trade cards.
/// @author The CryptoStrikers Team
contract StrikersTrading is StrikersMinting, Pausable {

  /// @dev Emitting this allows us to look up if a trade has been
  ///   successfully filled, by who, and with which card.
  event TradeFilled(
    bytes32 indexed tradeHash,
    address indexed maker,
    address taker,
    uint256 submittedCardId
  );

  /// @dev Emitting this allows us to look up if a trade has been cancelled.
  event TradeCancelled(bytes32 indexed tradeHash, address indexed maker);

  /// @dev All the possible states for a trade.
  enum TradeState {
    Valid,
    Filled,
    Cancelled
  }

  /// @dev Mapping of tradeHash => TradeState. Defaults to Valid.
  mapping (bytes32 => TradeState) public tradeStates;

  /// @dev A taker (someone who has received a signed trade hash)
  ///   submits a cardId to this function and, if it satisfies
  ///   the given criteria, the trade is executed.
  /// @param _maker Address of the maker (i.e. trade creator).
  /// @param _makerCardId ID of the card the maker has agreed to give up.
  /// @param _taker The counterparty the maker wishes to trade with (if it's address(0), anybody can fill the trade!)
  /// @param _takerCardOrChecklistId If taker is the 0-address, then this is a checklist ID (e.g. "any Lionel Messi").
  ///                                If not, then it's a card ID (e.g. "Lionel Messi #8/100").
  /// @param _salt A uint256 timestamp to differentiate trades that have otherwise identical params (prevents replay attacks).
  /// @param _submittedCardId The card the taker is using to fill the trade. Must satisfy either the card or checklist ID
  ///                         specified in _takerCardOrChecklistId.
  /// @param _v ECDSA signature parameter v from the tradeHash signed by the maker.
  /// @param _r ECDSA signature parameters r from the tradeHash signed by the maker.
  /// @param _s ECDSA signature parameters s from the tradeHash signed by the maker.
  function fillTrade(
    address _maker,
    uint256 _makerCardId,
    address _taker,
    uint256 _takerCardOrChecklistId,
    uint256 _salt,
    uint256 _submittedCardId,
    uint8 _v,
    bytes32 _r,
    bytes32 _s)
    external
    whenNotPaused
  {
    require(_maker != msg.sender, "You can't fill your own trade.");
    require(_taker == address(0) || _taker == msg.sender, "You are not authorized to fill this trade.");

    // More readable than a ternary operator?
    if (_taker == address(0)) {
      require(cards[_submittedCardId].checklistId == _takerCardOrChecklistId, "The card you submitted is not valid for this trade.");
    } else {
      require(_submittedCardId == _takerCardOrChecklistId, "The card you submitted is not valid for this trade.");
    }

    bytes32 tradeHash = getTradeHash(
      _maker,
      _makerCardId,
      _taker,
      _takerCardOrChecklistId,
      _salt
    );

    require(tradeStates[tradeHash] == TradeState.Valid, "This trade is no longer valid.");
    require(isValidSignature(_maker, tradeHash, _v, _r, _s), "Invalid signature");

    tradeStates[tradeHash] = TradeState.Filled;

    // For better UX, we assume that by signing the trade, the maker has given
    // implicit approval for this token to be transferred. This saves us from an
    // extra approval transaction...
    tokenApprovals[_makerCardId] = msg.sender;

    safeTransferFrom(_maker, msg.sender, _makerCardId);
    safeTransferFrom(msg.sender, _maker, _submittedCardId);

    emit TradeFilled(tradeHash, _maker, msg.sender, _submittedCardId);
  }

  /// @dev Allows the maker to cancel a trade that hasn't been filled yet.
  /// @param _maker Address of the maker (i.e. trade creator).
  /// @param _makerCardId ID of the card the maker has agreed to give up.
  /// @param _taker The counterparty the maker wishes to trade with (if it's address(0), anybody can fill the trade!)
  /// @param _takerCardOrChecklistId If taker is the 0-address, then this is a checklist ID (e.g. "any Lionel Messi").
  ///                                If not, then it's a card ID (e.g. "Lionel Messi #8/100").
  /// @param _salt A uint256 timestamp to differentiate trades that have otherwise identical params (prevents replay attacks).
  function cancelTrade(
    address _maker,
    uint256 _makerCardId,
    address _taker,
    uint256 _takerCardOrChecklistId,
    uint256 _salt)
    external
  {
    require(_maker == msg.sender, "Only the trade creator can cancel this trade.");

    bytes32 tradeHash = getTradeHash(
      _maker,
      _makerCardId,
      _taker,
      _takerCardOrChecklistId,
      _salt
    );

    require(tradeStates[tradeHash] == TradeState.Valid, "This trade has already been cancelled or filled.");
    tradeStates[tradeHash] = TradeState.Cancelled;
    emit TradeCancelled(tradeHash, _maker);
  }

  /// @dev Calculates Keccak-256 hash of a trade with specified parameters.
  /// @param _maker Address of the maker (i.e. trade creator).
  /// @param _makerCardId ID of the card the maker has agreed to give up.
  /// @param _taker The counterparty the maker wishes to trade with (if it's address(0), anybody can fill the trade!)
  /// @param _takerCardOrChecklistId If taker is the 0-address, then this is a checklist ID (e.g. "any Lionel Messi").
  ///                                If not, then it's a card ID (e.g. "Lionel Messi #8/100").
  /// @param _salt A uint256 timestamp to differentiate trades that have otherwise identical params (prevents replay attacks).
  /// @return Keccak-256 hash of trade.
  function getTradeHash(
    address _maker,
    uint256 _makerCardId,
    address _taker,
    uint256 _takerCardOrChecklistId,
    uint256 _salt)
    public
    view
    returns (bytes32)
  {
    // Hashing the contract address prevents a trade from being replayed on any new trade contract we deploy.
    bytes memory packed = abi.encodePacked(this, _maker, _makerCardId, _taker, _takerCardOrChecklistId, _salt);
    return keccak256(packed);
  }

  /// @dev Verifies that a signed trade is valid.
  /// @param _signer Address of signer.
  /// @param _tradeHash Signed Keccak-256 hash.
  /// @param _v ECDSA signature parameter v.
  /// @param _r ECDSA signature parameters r.
  /// @param _s ECDSA signature parameters s.
  /// @return Validity of signature.
  function isValidSignature(
    address _signer,
    bytes32 _tradeHash,
    uint8 _v,
    bytes32 _r,
    bytes32 _s)
    public
    pure
    returns (bool)
  {
    bytes memory packed = abi.encodePacked("\x19Ethereum Signed Message:\n32", _tradeHash);
    return _signer == ecrecover(keccak256(packed), _v, _r, _s);
  }
}
