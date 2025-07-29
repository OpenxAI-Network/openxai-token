import { Address, DeployInfo, Deployer } from "../../web3webdeploy/types";

export interface DeployOpenxAIGenesisSettings
  extends Omit<DeployInfo, "contract" | "args"> {
  receiver: Address;
  ethOracle: Address;
  wrappedEth: Address[];
  stableCoins: Address[];
  tiers: bigint[];
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
        settings.receiver,
        settings.ethOracle,
        settings.wrappedEth,
        settings.stableCoins,
        settings.tiers,
      ],
      ...settings,
    })
    .then((deployment) => deployment.address);
}
