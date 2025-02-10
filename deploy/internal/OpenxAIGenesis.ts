import { Address, DeployInfo, Deployer } from "../../web3webdeploy/types";

export interface DeployOpenxAIGenesisSettings
  extends Omit<DeployInfo, "contract" | "args"> {
  ethOracle: Address;
  wrappedEth: Address[];
  stableCoins: Address[];
  tiers: { amount: bigint; escrow: Address }[];
}

export async function deployOpenxAIGenesis(
  deployer: Deployer,
  settings: DeployOpenxAIGenesisSettings
): Promise<Address> {
  return await deployer
    .deploy({
      id: "OpenxAIGenesis",
      contract: "OpenxAIGenesis",
      args: [
        settings.ethOracle,
        settings.wrappedEth,
        settings.stableCoins,
        settings.tiers,
      ],
      ...settings,
    })
    .then((deployment) => deployment.address);
}
