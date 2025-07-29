// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {EIP712} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import {IMintable} from "./IMintable.sol";

import {Rescue} from "./Rescue.sol";

bytes32 constant CLAIM_TYPEHASH = keccak256(
  "Claim(address claimer,uint256 total)"
);

contract OpenxAIClaimer is Ownable, EIP712, Rescue {
  error ProofAlreadyClaimed();
  error TokenSpendingLimitReached();
  error InvalidProof();

  event TokensClaimed(address indexed account, uint256 total, uint256 released);

  IMintable public immutable token;
  uint256 public immutable tokenSpendingLimit;
  uint256 public immutable spendingPeriodDuration;
  mapping(address account => uint256 claimed) public claimed;

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

  /// Claim your tokens with a proof from an off-chain signer.
  /// @param _v V component of the server proof signature.
  /// @param _r R component of the server proof signature.
  /// @param _s S component of the server proof signature.
  /// @param _claimer To which address the tokens are sent.
  /// @param _total How many tokens this address can claim in total (including previously claimed).
  function claim(
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    address _claimer,
    uint256 _total
  ) external {
    uint256 amount = _total - claimed[_claimer];

    uint256 spendingPeriod = block.timestamp / spendingPeriodDuration;
    uint256 tokenSpending = amount;
    if (spendingPeriod == currentSpendingPeriod) {
      // Withing the same spending period
      tokenSpending += currentTokenSpending;
    }
    if (tokenSpending > tokenSpendingLimit) {
      revert TokenSpendingLimitReached();
    }

    address signer = ECDSA.recover(
      _hashTypedDataV4(keccak256(abi.encode(CLAIM_TYPEHASH, _claimer, _total))),
      _v,
      _r,
      _s
    );
    if (signer != owner()) {
      revert InvalidProof();
    }

    token.mint(_claimer, amount);
    emit TokensClaimed(_claimer, _total, amount);

    claimed[_claimer] = _total;
    if (currentSpendingPeriod != spendingPeriod) {
      currentSpendingPeriod = spendingPeriod;
    }
    if (currentTokenSpending != tokenSpending) {
      currentTokenSpending = tokenSpending;
    }
  }
}
