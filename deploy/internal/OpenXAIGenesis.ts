import { Address, DeployInfo, Deployer } from "../../web3webdeploy/types";

export interface DeployOpenXAIGenesisSettings
  extends Omit<DeployInfo, "contract" | "args"> {
  ethOracle: Address;
  wrappedEth: Address[];
  stableCoins: Address[];
  tiers: {amount: bigint, escrow: Address}[]
}

export async function deployOpenXAIGenesis(
  deployer: Deployer,
  settings: DeployOpenXAIGenesisSettings
): Promise<Address> {
  return await deployer
    .deploy({
      id: "OpenXAIGenesis",
      contract: "OpenXAIGenesis",
      args: [settings.ethOracle, settings.wrappedEth, settings.stableCoins, settings.tiers],
      ...settings,
    })
    .then((deployment) => deployment.address);
}
