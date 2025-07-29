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
    receiver: "0x519ce4C129a981B2CBB4C3990B1391dA24E8EbF3",
    tiers: ["10000", "15000", "20000", "25000", "30000", "50000"].map((a) =>
      deployer.viem.parseUnits(a, 6)
    ),
    ...(deployer.settings.defaultChainId === 8453
      ? {
          ethOracle: "0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70", // https://docs.chain.link/data-feeds/price-feeds/addresses?page=1&testnetPage=1&network=base&search=eth%2Fusd
          wrappedEth: ["0x4200000000000000000000000000000000000006"],
          stableCoins: [
            "0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2", // USDT
            "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913", // USDC
          ],
        }
      : {
          ethOracle: "0x694AA1769357215DE4FAC081bf1f309aDC325306", // https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1#sepolia-testnet
          wrappedEth: [],
          stableCoins: ["0xEE5b5633B8fa453bD1a4A24973c742BD0488D1C6"], // USDP
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
