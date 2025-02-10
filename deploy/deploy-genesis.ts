import { Address, Deployer } from "../web3webdeploy/types";
import {
  deployOpenxAIGenesis,
  DeployOpenxAIGenesisSettings,
} from "./internal/OpenxAIGenesis";

export interface DeploymentSettings {
  genesisSettings: Partial<DeployOpenxAIGenesisSettings>;
  forceRedeploy?: boolean;
}

export interface Deployment {
  genesis: Address;
}

export async function deploy(
  deployer: Deployer,
  settings?: DeploymentSettings
): Promise<Deployment> {
  if (settings?.forceRedeploy !== undefined && !settings.forceRedeploy) {
    const existingDeployment = await deployer.loadDeployment({
      deploymentName: "genesis.json",
    });
    if (existingDeployment !== undefined) {
      return existingDeployment;
    }
  }

  const genesis = await deployOpenxAIGenesis(deployer, {
    tiers: [
      {
        amount: deployer.viem.parseUnits("10000", 6),
        escrow: "0x519ce4C129a981B2CBB4C3990B1391dA24E8EbF3",
      },
      {
        amount: deployer.viem.parseUnits("5000", 6),
        escrow: "0x519ce4C129a981B2CBB4C3990B1391dA24E8EbF3",
      },
      {
        amount: deployer.viem.parseUnits("25000", 6),
        escrow: "0x519ce4C129a981B2CBB4C3990B1391dA24E8EbF3",
      },
    ],
    ...(deployer.settings.defaultChainId === 11155111
      ? {
          ethOracle: "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419", // https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1#sepolia-testnet
          wrappedEth: ["0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9"],
          stableCoins: [],
        }
      : {
          ethOracle: "0x694AA1769357215DE4FAC081bf1f309aDC325306", // https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1&search=eth%2Fusd#ethereum-mainnet
          wrappedEth: ["0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"],
          stableCoins: [
            "0xdAC17F958D2ee523a2206206994597C13D831ec7", // USDT
            "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", // USDC
          ],
        }),
    ...settings?.genesisSettings,
  });

  const deployment = { genesis };
  await deployer.saveDeployment({
    deploymentName: "genesis.json",
    deployment: deployment,
  });
  return deployment;
}
