pragma solidity 0.4.24;

import "./StrikersMetadata.sol";
import "./StrikersTrading.sol";

/// @title The main, ERC721-compliant CryptoStrikers contract.
/// @author The CryptoStrikers Team
contract StrikersCore is StrikersTrading {

  /// @dev An external metadata contract that the owner can upgrade.
  StrikersMetadata public strikersMetadata;

  /// @dev We initialize the CryptoStrikers game with an immutable checklist that oversees card rarity.
  constructor(address _checklistAddress) public {
    strikersChecklist = StrikersChecklist(_checklistAddress);
  }

  /// @dev Allows the contract owner to update the metadata contract.
  function setMetadataAddress(address _contractAddress) external onlyOwner {
    strikersMetadata = StrikersMetadata(_contractAddress);
  }

  /// @dev If we've set an external metadata contract, use that.
  function tokenURI(uint256 _tokenId) public view returns (string) {
    if (strikersMetadata == address(0)) {
      return super.tokenURI(_tokenId);
    }

    require(exists(_tokenId), "Card does not exist.");
    return strikersMetadata.tokenURI(_tokenId);
  }
}
