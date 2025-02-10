// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20, IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "../lib/openzeppelin-contracts/contracts/utils/Address.sol";

import {AggregatorV3Interface} from "../lib/chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {Rescue} from "./Rescue.sol";

contract OpenxAIGenesis is Rescue {
  error UnsupportedTransferToken(IERC20 token);
  error InvalidPrice(int256 price);

  event Participated(
    uint256 indexed tier,
    address indexed account,
    uint256 amount
  );

  /// Convert ETH to stable coin value
  AggregatorV3Interface internal ethOracle;

  /// Token that is required to be transferred.
  mapping(IERC20 => bool) internal wrappedEth;
  mapping(IERC20 => bool) internal stableCoin;

  /// Milestones that the transferred funds will be allocated to
  struct Tier {
    uint96 amount;
    address payable escrow;
  }
  Tier[] public tiers;

  constructor(
    AggregatorV3Interface _ethOracle,
    IERC20[] memory _wrappedEth,
    IERC20[] memory _stableCoins,
    Tier[] memory _tiers
  ) {
    ethOracle = _ethOracle;
    for (uint256 i; i < _wrappedEth.length; i++) {
      wrappedEth[_wrappedEth[i]] = true;
    }
    for (uint256 i; i < _stableCoins.length; i++) {
      stableCoin[_stableCoins[i]] = true;
    }
    tiers = _tiers;
  }

  function transfer_native() external payable {
    _native_contribution();
  }

  function transfer_erc20(IERC20 _token, uint256 _amount) external {
    if (wrappedEth[_token]) {
      _wrappedeth_contribution(_token, _amount);
    } else if (stableCoin[_token]) {
      _stablecoin_contribution(_token, _amount);
    } else {
      revert UnsupportedTransferToken(_token);
    }
  }

  function _eth_price() internal view returns (uint256 price) {
    (, int256 ethPrice, , , ) = ethOracle.latestRoundData();
    if (ethPrice < 0) {
      revert InvalidPrice(ethPrice);
    }

    // Assume decimals of price oracle is 8, while stable coin is 6
    price = uint256(ethPrice / 100);
  }

  function _native_contribution() internal {
    uint256 usdTotal = (msg.value * _eth_price()) / (10 ** 18);
    uint256 usdRemaining = usdTotal;
    uint256 ethRemaining = msg.value;

    for (uint256 i; i < tiers.length; i++) {
      uint96 usdInTier = tiers[i].amount;
      if (usdInTier == 0) {
        // Tier empty, skip (save gas)
        continue;
      }

      if (usdInTier >= usdRemaining) {
        // contribution fits within this tier
        Address.sendValue(tiers[i].escrow, ethRemaining);
        emit Participated(i, msg.sender, usdRemaining);
        tiers[i].amount -= uint96(usdRemaining); // usd remaining is smaller than usd in tier, thus fits in uint96
        return;
      } else {
        // contribution overflows to next tier
        uint256 ethUsed = (usdInTier * msg.value) / usdTotal;
        Address.sendValue(tiers[i].escrow, ethUsed);
        emit Participated(i, msg.sender, usdInTier);
        ethRemaining -= ethUsed;
        usdRemaining -= usdInTier;
        tiers[i].amount = 0;
      }
    }

    // Refund leftover ETH if tiers are full
    Address.sendValue(payable(msg.sender), ethRemaining);
  }

  function _wrappedeth_contribution(IERC20 _token, uint256 _amount) internal {
    uint256 usdTotal = (_amount * _eth_price()) / (10 ** 18);
    uint256 usdRemaining = usdTotal;
    uint256 ethRemaining = _amount;

    for (uint256 i; i < tiers.length; i++) {
      uint96 usdInTier = tiers[i].amount;
      if (usdInTier == 0) {
        // Tier empty, skip (save gas)
        continue;
      }

      if (usdInTier >= usdRemaining) {
        // contribution fits within this tier
        SafeERC20.safeTransferFrom(
          _token,
          msg.sender,
          tiers[i].escrow,
          ethRemaining
        );
        emit Participated(i, msg.sender, usdRemaining);
        tiers[i].amount -= uint96(usdRemaining); // usd remaining is smaller than usd in tier, thus fits in uint96
        return;
      } else {
        // contribution overflows to next tier
        uint256 ethUsed = (usdInTier * _amount) / usdTotal;
        SafeERC20.safeTransferFrom(
          _token,
          msg.sender,
          tiers[i].escrow,
          ethUsed
        );
        emit Participated(i, msg.sender, usdInTier);
        ethRemaining -= ethUsed;
        usdRemaining -= usdInTier;
        tiers[i].amount = 0;
      }
    }
  }

  function _stablecoin_contribution(IERC20 _token, uint256 _amount) internal {
    uint256 usdTotal = _amount;
    uint256 usdRemaining = usdTotal;

    for (uint256 i; i < tiers.length; i++) {
      uint96 usdInTier = tiers[i].amount;
      if (usdInTier == 0) {
        // Tier empty, skip (save gas)
        continue;
      }

      if (usdInTier >= usdRemaining) {
        // contribution fits within this tier
        SafeERC20.safeTransferFrom(
          _token,
          msg.sender,
          tiers[i].escrow,
          usdRemaining
        );
        emit Participated(i, msg.sender, usdRemaining);
        tiers[i].amount -= uint96(usdRemaining); // usd remaining is smaller than usd in tier, thus fits in uint96
        return;
      } else {
        // contribution overflows to next tier
        SafeERC20.safeTransferFrom(
          _token,
          msg.sender,
          tiers[i].escrow,
          usdInTier
        );
        emit Participated(i, msg.sender, usdInTier);
        usdRemaining -= usdInTier;
        tiers[i].amount = 0;
      }
    }
  }
}
