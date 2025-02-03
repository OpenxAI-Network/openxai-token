// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "../lib/forge-std/src/Test.sol";
import {OpenXAI} from "../src/OpenXAI.sol";
import {OpenXAIGenesis, IMintable, IERC20} from "../src/OpenXAIGenesis.sol";

import {ERC1967Proxy} from "../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MockTokenFactory {
  function createToken() external returns (OpenXAI token) {
    token = OpenXAI(
      address(
        new ERC1967Proxy(
          address(new OpenXAI()),
          abi.encodeCall(OpenXAI.initialize, ())
        )
      )
    );
  }
}

contract OpenXAIGenesisTest is Test {
  OpenXAI transferToken;
  OpenXAI distributeToken;

  function setUp() public {
    MockTokenFactory tokenFactory = new MockTokenFactory();
    transferToken = tokenFactory.createToken();
    distributeToken = tokenFactory.createToken();
  }

  function createDistributor(
    uint256 rate
  ) internal returns (OpenXAIGenesis distributor) {
    distributor = new OpenXAIGenesis(
      IERC20(transferToken),
      IMintable(distributeToken),
      rate
    );

    vm.startPrank(distributeToken.ADMIN());
    distributeToken.grantRole(
      distributeToken.MINT_ROLE(),
      address(distributor)
    );
    vm.stopPrank();
  }

  function test_genesis(uint128 rate, uint128 amount) public {
    OpenXAIGenesis distributor = createDistributor(rate);

    vm.startPrank(transferToken.ADMIN());
    transferToken.grantRole(transferToken.MINT_ROLE(), address(this));
    vm.stopPrank();

    transferToken.mint(address(this), amount);

    transferToken.approve(address(distributor), amount);
    distributor.genesis(amount);

    assertEq(transferToken.balanceOf(address(this)), 0);
    assertEq(distributeToken.balanceOf(address(this)), uint256(amount) * rate);
  }
}
