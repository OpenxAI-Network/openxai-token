// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "../lib/forge-std/src/Test.sol";
import {OpenXAI} from "../src/OpenXAI.sol";
import {OpenXAIGenesis, IERC20, AggregatorV3Interface} from "../src/OpenXAIGenesis.sol";

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

contract OpenXAIGenesisTest is Test {
  OpenXAI weth;
  OpenXAI stablecoin;
  AggregatorV3Interface ethOracle;
  OpenXAIGenesis distributor;

  function setUp() public {
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

    OpenXAIGenesis.Tier[] memory tiers = new OpenXAIGenesis.Tier[](5);
    tiers[0] = OpenXAIGenesis.Tier(1000000000, address(1)); // 1000 USD
    tiers[1] = OpenXAIGenesis.Tier(10000000000, address(2)); // 10000 USD
    tiers[2] = OpenXAIGenesis.Tier(100000000000, address(3)); // 100000 USD
    tiers[3] = OpenXAIGenesis.Tier(1000000, address(4)); // 1 USD
    tiers[4] = OpenXAIGenesis.Tier(1000000000, address(5)); // 1000 USD

    distributor = new OpenXAIGenesis(ethOracle, wrappedEth, stableCoins, tiers);
  }

  function test_stablecoin_single_tier(
    address contributor,
    uint8 amount
  ) public {
    vm.assume(contributor != address(0) && amount != 0);

    (, address firstTierEscrow) = distributor.tiers(0);

    stablecoin.mint(contributor, amount);

    vm.startPrank(contributor);

    stablecoin.approve(address(distributor), amount);

    vm.expectEmit(address(distributor));
    emit OpenXAIGenesis.Participated(0, contributor, amount);

    distributor.transfer_erc20(IERC20(address(stablecoin)), amount);

    vm.stopPrank();

    assertEq(stablecoin.balanceOf(firstTierEscrow), amount);
  }

  function test_stablecoin_two_tier(
    address contributor,
    uint8 amountAfterFirstTier
  ) public {
    vm.assume(contributor != address(0) && amountAfterFirstTier != 0);

    (uint96 firstTierMax, address firstTierEscrow) = distributor.tiers(0);
    (, address secondTierEscrow) = distributor.tiers(1);
    uint96 amount = firstTierMax + amountAfterFirstTier;

    stablecoin.mint(contributor, amount);

    vm.startPrank(contributor);

    stablecoin.approve(address(distributor), amount);

    vm.expectEmit(address(distributor));
    emit OpenXAIGenesis.Participated(0, contributor, firstTierMax);

    vm.expectEmit(address(distributor));
    emit OpenXAIGenesis.Participated(1, contributor, amountAfterFirstTier);

    distributor.transfer_erc20(IERC20(address(stablecoin)), amount);

    vm.stopPrank();

    assertEq(stablecoin.balanceOf(firstTierEscrow), firstTierMax);
    assertEq(stablecoin.balanceOf(secondTierEscrow), amountAfterFirstTier);
  }

  function test_stablecoin_three_tier(
    address contributor,
    uint8 amountAfterSecondTier
  ) public {
    vm.assume(contributor != address(0) && amountAfterSecondTier != 0);

    (uint96 firstTierMax, address firstTierEscrow) = distributor.tiers(0);
    (uint96 secondTierMax, address secondTierEscrow) = distributor.tiers(1);
    (, address thirdTierEscrow) = distributor.tiers(2);
    uint96 amount = firstTierMax + secondTierMax + amountAfterSecondTier;

    stablecoin.mint(contributor, amount);

    vm.startPrank(contributor);

    stablecoin.approve(address(distributor), amount);

    vm.expectEmit(address(distributor));
    emit OpenXAIGenesis.Participated(0, contributor, firstTierMax);

    vm.expectEmit(address(distributor));
    emit OpenXAIGenesis.Participated(1, contributor, secondTierMax);

    vm.expectEmit(address(distributor));
    emit OpenXAIGenesis.Participated(2, contributor, amountAfterSecondTier);

    distributor.transfer_erc20(IERC20(address(stablecoin)), amount);

    vm.stopPrank();

    assertEq(stablecoin.balanceOf(firstTierEscrow), firstTierMax);
    assertEq(stablecoin.balanceOf(secondTierEscrow), secondTierMax);
    assertEq(stablecoin.balanceOf(thirdTierEscrow), amountAfterSecondTier);
  }

  function test_weth_three_tier(address contributor) public {
    vm.assume(contributor != address(0));
    // ETH oracle should use 3123 ETH/USD
    uint256 eth = 5 ether;
    uint96 usd = 5 * 3123 * 10 ** 6;

    (uint96 firstTierMax, address firstTierEscrow) = distributor.tiers(0);
    (uint96 secondTierMax, address secondTierEscrow) = distributor.tiers(1);
    (, address thirdTierEscrow) = distributor.tiers(2);
    uint96 amountAfterSecondTier = usd - firstTierMax - secondTierMax;

    weth.mint(contributor, eth);

    vm.startPrank(contributor);

    weth.approve(address(distributor), eth);

    vm.expectEmit(address(distributor));
    emit OpenXAIGenesis.Participated(0, contributor, firstTierMax);

    vm.expectEmit(address(distributor));
    emit OpenXAIGenesis.Participated(1, contributor, secondTierMax);

    vm.expectEmit(address(distributor));
    emit OpenXAIGenesis.Participated(2, contributor, amountAfterSecondTier);

    distributor.transfer_erc20(IERC20(address(weth)), eth);

    vm.stopPrank();

    // Allowed to be off by $0.0001 due to rounding errors
    assertApproxEqAbs(
      weth.balanceOf(firstTierEscrow),
      (firstTierMax * 10 ** 12) / 3123,
      100
    );
    assertApproxEqAbs(
      weth.balanceOf(secondTierEscrow),
      (secondTierMax * 10 ** 12) / 3123,
      100
    );
    assertApproxEqAbs(
      weth.balanceOf(thirdTierEscrow),
      (amountAfterSecondTier * 10 ** 12) / 3123,
      100
    );
  }

  function test_native_three_tier(address contributor) public {
    vm.assume(contributor != address(0));
    // ETH oracle should use 3123 ETH/USD
    uint256 eth = 5 ether;
    uint96 usd = 5 * 3123 * 10 ** 6;

    (uint96 firstTierMax, address firstTierEscrow) = distributor.tiers(0);
    (uint96 secondTierMax, address secondTierEscrow) = distributor.tiers(1);
    (, address thirdTierEscrow) = distributor.tiers(2);
    uint96 amountAfterSecondTier = usd - firstTierMax - secondTierMax;

    vm.deal(contributor, eth);

    vm.startPrank(contributor);

    vm.expectEmit(address(distributor));
    emit OpenXAIGenesis.Participated(0, contributor, firstTierMax);

    vm.expectEmit(address(distributor));
    emit OpenXAIGenesis.Participated(1, contributor, secondTierMax);

    vm.expectEmit(address(distributor));
    emit OpenXAIGenesis.Participated(2, contributor, amountAfterSecondTier);

    distributor.transfer_native{value: eth}();

    vm.stopPrank();

    // Allowed to be off by $0.0001 due to rounding errors
    assertApproxEqAbs(
      firstTierEscrow.balance,
      (firstTierMax * 10 ** 12) / 3123,
      100
    );
    assertApproxEqAbs(
      secondTierEscrow.balance,
      (secondTierMax * 10 ** 12) / 3123,
      100
    );
    assertApproxEqAbs(
      thirdTierEscrow.balance,
      (amountAfterSecondTier * 10 ** 12) / 3123,
      100
    );
  }
}
