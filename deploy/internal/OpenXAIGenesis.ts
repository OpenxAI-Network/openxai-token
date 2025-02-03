import { Address, DeployInfo, Deployer } from "../../web3webdeploy/types";

export interface DeployOpenXAIGenesisSettings
  extends Omit<DeployInfo, "contract" | "args"> {
  openXAI: Address;
  USDC: Address;
  rate: bigint;
}

export async function deployOpenXAIGenesis(
  deployer: Deployer,
  settings: DeployOpenXAIGenesisSettings
): Promise<Address> {
  return await deployer
    .deploy({
      id: "OpenXAIGenesis",
      contract: "OpenXAIGenesis",
      args: [settings.USDC, settings.openXAI, settings.rate],
      ...settings,
    })
    .then((deployment) => deployment.address);
}
