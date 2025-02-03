// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMintable} from "./IMintable.sol";
import {SafeERC20, IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract OpenXAIGenesis {
  /// Token that is required to be transferred.
  IERC20 public immutable transferToken;

  /// Token that is received.
  IMintable public immutable distributeToken;

  /// Amount of tokens received per token transferred.
  uint256 public distributePerTransfer;

  constructor(
    IERC20 _transferToken,
    IMintable _distributeToken,
    uint256 _distributePerTransfer
  ) {
    transferToken = _transferToken;
    distributeToken = _distributeToken;
    distributePerTransfer = _distributePerTransfer;
  }

  function genesis(uint256 _amount) external payable {
    SafeERC20.safeTransferFrom(
      transferToken,
      msg.sender,
      address(this),
      _amount
    );
    distributeToken.mint(msg.sender, _amount * distributePerTransfer);
  }
}
