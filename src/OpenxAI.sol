// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC20VotesUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import {AccessControlUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {IMintable} from "./IMintable.sol";

contract OpenxAI is
  Initializable,
  UUPSUpgradeable,
  ERC20VotesUpgradeable,
  AccessControlUpgradeable,
  IMintable
{
  bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE");
  bytes32 public constant MINT_ROLE = keccak256("MINT");

  address public constant ADMIN = 0x3e166454c7781d3fD4ceaB18055cad87136970Ea;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize() public initializer {
    __UUPSUpgradeable_init();
    __ERC20_init("OpenxAI", "OPENX");
    __AccessControl_init();
    _grantRole(DEFAULT_ADMIN_ROLE, ADMIN);
  }

  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyRole(UPGRADE_ROLE) {}

  // @inheritdoc IMintable
  function mint(address account, uint256 amount) external onlyRole(MINT_ROLE) {
    _mint(account, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }
}
