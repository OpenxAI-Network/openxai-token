// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "../lib/forge-std/src/Test.sol";
import {OpenxAI} from "../src/OpenxAI.sol";
import {OpenxAIGenesis, IERC20, AggregatorV3Interface} from "../src/OpenxAIGenesis.sol";

import {ERC1967Proxy} from "../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MockTokenFactory {
  function createToken() external returns (OpenxAI token) {
    token = OpenxAI(
      address(
        new ERC1967Proxy(
          address(new OpenxAI()),
          abi.encodeCall(OpenxAI.initialize, ())
        )
      )
    );
  }
}

contract MockEthOracle is AggregatorV3Interface {
  function decimals() external pure returns (uint8) {
    return 8;
  }

  function description() external pure returns (string memory) {
    return "";
  }

  function version() external pure returns (uint256) {
    return 1;
  }

  function getRoundData(
    uint80 _roundId
  )
    public
    pure
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (_roundId, 3123 * 10 ** 8, 0, 0, 0);
  }

  function latestRoundData()
    external
    pure
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return getRoundData(0);
  }
}

contract OpenxAIGenesisTest is Test {
  address payable receiver;
  OpenxAI weth;
  OpenxAI stablecoin;
  AggregatorV3Interface ethOracle;
  OpenxAIGenesis distributor;

  function setUp() public {
    receiver = payable(address(1));
    MockTokenFactory tokenFactory = new MockTokenFactory();
    weth = tokenFactory.createToken();
    stablecoin = tokenFactory.createToken();
    ethOracle = new MockEthOracle();

    IERC20[] memory wrappedEth = new IERC20[](1);
    wrappedEth[0] = IERC20(address(weth));
    IERC20[] memory stableCoins = new IERC20[](1);
    stableCoins[0] = IERC20(address(stablecoin));

    vm.startPrank(weth.ADMIN());
    weth.grantRole(weth.MINT_ROLE(), address(this));
    stablecoin.grantRole(stablecoin.MINT_ROLE(), address(this));
    vm.stopPrank();

    uint256[] memory tiers = new uint256[](5);
    tiers[0] = 1000000000; // 1000 USD
    tiers[1] = 10000000000; // 10000 USD
    tiers[2] = 100000000000; // 100000 USD
    tiers[3] = 1000000; // 1 USD
    tiers[4] = 1000000000; // 1000 USD

    distributor = new OpenxAIGenesis(
      receiver,
      ethOracle,
      wrappedEth,
      stableCoins,
      tiers
    );
  }

  function test_stablecoin_single_tier(
    address contributor,
    uint8 amount
  ) public {
    vm.assume(contributor != address(0) && amount != 0);

    stablecoin.mint(contributor, amount);

    vm.startPrank(contributor);

    stablecoin.approve(address(distributor), amount);

    vm.expectEmit(address(distributor));
    emit OpenxAIGenesis.Participated(0, contributor, amount);

    distributor.transfer_erc20(IERC20(address(stablecoin)), amount);

    vm.stopPrank();

    assertEq(stablecoin.balanceOf(receiver), amount);
  }

  function test_stablecoin_two_tier(
    address contributor,
    uint8 amountAfterFirstTier
  ) public {
    vm.assume(contributor != address(0) && amountAfterFirstTier != 0);

    uint256 firstTierMax = distributor.tiers(0);
    uint256 amount = firstTierMax + amountAfterFirstTier;

    stablecoin.mint(contributor, amount);

    vm.startPrank(contributor);

    stablecoin.approve(address(distributor), amount);

    vm.expectEmit(address(distributor));
    emit OpenxAIGenesis.Participated(0, contributor, firstTierMax);

    vm.expectEmit(address(distributor));
    emit OpenxAIGenesis.Participated(1, contributor, amountAfterFirstTier);

    distributor.transfer_erc20(IERC20(address(stablecoin)), amount);

    vm.stopPrank();

    assertEq(stablecoin.balanceOf(receiver), amount);
  }

  function test_stablecoin_three_tier(
    address contributor,
    uint8 amountAfterSecondTier
  ) public {
    vm.assume(contributor != address(0) && amountAfterSecondTier != 0);

    uint256 firstTierMax = distributor.tiers(0);
    uint256 secondTierMax = distributor.tiers(1);
    uint256 amount = firstTierMax + secondTierMax + amountAfterSecondTier;

    stablecoin.mint(contributor, amount);

    vm.startPrank(contributor);

    stablecoin.approve(address(distributor), amount);

    vm.expectEmit(address(distributor));
    emit OpenxAIGenesis.Participated(0, contributor, firstTierMax);

    vm.expectEmit(address(distributor));
    emit OpenxAIGenesis.Participated(1, contributor, secondTierMax);

    vm.expectEmit(address(distributor));
    emit OpenxAIGenesis.Participated(2, contributor, amountAfterSecondTier);

    distributor.transfer_erc20(IERC20(address(stablecoin)), amount);

    vm.stopPrank();

    assertEq(stablecoin.balanceOf(receiver), amount);
  }

  function test_weth_three_tier(address contributor) public {
    vm.assume(contributor != address(0));
    // ETH oracle should use 3123 ETH/USD
    uint256 eth = 5 ether;
    uint256 usd = 5 * 3123 * 10 ** 6;

    uint256 firstTierMax = distributor.tiers(0);
    uint256 secondTierMax = distributor.tiers(1);
    uint256 amountAfterSecondTier = usd - firstTierMax - secondTierMax;

    weth.mint(contributor, eth);

    vm.startPrank(contributor);

    weth.approve(address(distributor), eth);

    vm.expectEmit(address(distributor));
    emit OpenxAIGenesis.Participated(0, contributor, firstTierMax);

    vm.expectEmit(address(distributor));
    emit OpenxAIGenesis.Participated(1, contributor, secondTierMax);

    vm.expectEmit(address(distributor));
    emit OpenxAIGenesis.Participated(2, contributor, amountAfterSecondTier);

    distributor.transfer_erc20(IERC20(address(weth)), eth);

    vm.stopPrank();

    assertEq(weth.balanceOf(receiver), eth);
  }

  function test_native_three_tier(address contributor) public {
    vm.assume(contributor != address(0));
    // ETH oracle should use 3123 ETH/USD
    uint256 eth = 5 ether;
    uint256 usd = 5 * 3123 * 10 ** 6;

    uint256 firstTierMax = distributor.tiers(0);
    uint256 secondTierMax = distributor.tiers(1);
    uint256 amountAfterSecondTier = usd - firstTierMax - secondTierMax;

    vm.deal(contributor, eth);

    vm.startPrank(contributor);

    vm.expectEmit(address(distributor));
    emit OpenxAIGenesis.Participated(0, contributor, firstTierMax);

    vm.expectEmit(address(distributor));
    emit OpenxAIGenesis.Participated(1, contributor, secondTierMax);

    vm.expectEmit(address(distributor));
    emit OpenxAIGenesis.Participated(2, contributor, amountAfterSecondTier);

    distributor.transfer_native{value: eth}();

    vm.stopPrank();

    assertEq(receiver.balance, eth);
  }
}
