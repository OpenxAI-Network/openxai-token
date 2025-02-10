// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20, IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "../lib/openzeppelin-contracts/contracts/utils/Address.sol";

contract Rescue {
  address private constant RESCUE = 0x3e166454c7781d3fD4ceaB18055cad87136970Ea;
  error NotRescue(address caller, address rescue);

  function rescue(
    IERC20 _token,
    address payable _receiver,
    uint256 _amount
  ) external {
    if (msg.sender != RESCUE) {
      revert NotRescue(msg.sender, RESCUE);
    }

    if (address(_token) == address(0)) {
      Address.sendValue(_receiver, _amount);
    } else {
      SafeERC20.safeTransfer(_token, _receiver, _amount);
    }
  }
}
