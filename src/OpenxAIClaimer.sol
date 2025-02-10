// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {EIP712} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import {IMintable} from "./IMintable.sol";

bytes32 constant CLAIM_TYPEHASH = keccak256(
  "Claim(uint256 proofId,address claimer,uint256 amount)"
);

contract OpenxAIClaiming is Ownable, EIP712 {
  error ProofAlreadyClaimed();
  error TokenSpendingLimitReached();
  error InvalidProof();

  event TokensClaimed(address indexed account, uint256 amount);

  IMintable public immutable token;
  uint256 public tokenSpendingLimit;
  uint256 public spendingPeriodDuration;
  mapping(uint256 proofId => bool claimed) public proofClaimed;

  uint256 public currentTokenSpending;
  uint256 public currentSpendingPeriod;

  constructor(
    IMintable _token,
    uint256 _tokenSpendingLimit,
    uint256 _spendingPeriodDuration,
    address _signer
  ) Ownable(_signer) EIP712("OpenxAIClaiming", "1") {
    token = _token;
    tokenSpendingLimit = _tokenSpendingLimit;
    spendingPeriodDuration = _spendingPeriodDuration;
  }

  /// Claim your tokens, with a proof granted to you from our server for performing a certain action.
  /// @param _v V component of the server proof signature.
  /// @param _r R component of the server proof signature.
  /// @param _s S component of the server proof signature.
  /// @param _proofId Unique identifier of the proof.
  /// @param _claimer To which address the tokens are sent.
  /// @param _amount How many tokens are sent.
  function claim(
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    uint256 _proofId,
    address _claimer,
    uint256 _amount
  ) external {
    if (proofClaimed[_proofId]) {
      revert ProofAlreadyClaimed();
    }

    uint256 spendingPeriod = block.timestamp / spendingPeriodDuration;
    uint256 tokenSpending = _amount;
    if (spendingPeriod == currentSpendingPeriod) {
      // Withing the same spending period
      tokenSpending += currentTokenSpending;
    }
    if (tokenSpending > tokenSpendingLimit) {
      revert TokenSpendingLimitReached();
    }

    address signer = ECDSA.recover(
      _hashTypedDataV4(
        keccak256(abi.encode(CLAIM_TYPEHASH, _proofId, _claimer, _amount))
      ),
      _v,
      _r,
      _s
    );
    if (signer != owner()) {
      revert InvalidProof();
    }

    token.mint(_claimer, _amount);
    emit TokensClaimed(_claimer, _amount);

    proofClaimed[_proofId] = true;
    if (currentSpendingPeriod != spendingPeriod) {
      currentSpendingPeriod = spendingPeriod;
    }
    if (currentTokenSpending != tokenSpending) {
      currentTokenSpending = tokenSpending;
    }
  }
}
