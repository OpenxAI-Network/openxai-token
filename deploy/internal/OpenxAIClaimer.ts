import { Address, DeployInfo, Deployer } from "../../web3webdeploy/types";

export interface DeployOpenxAIClaimerSettings
  extends Omit<DeployInfo, "contract" | "args"> {
  token: Address;
  spendingLimit: bigint;
  spendingPeriod: bigint;
  signer: Address;
}

export async function deployOpenxAIClaimer(
  deployer: Deployer,
  settings: DeployOpenxAIClaimerSettings
): Promise<Address> {
  return await deployer
    .deploy({
      id: "OpenxAIClaimer",
      contract: "OpenxAIClaimer",
      args: [
        settings.token,
        settings.spendingLimit,
        settings.spendingPeriod,
        settings.signer,
      ],
      ...settings,
    })
    .then((deployment) => deployment.address);
}
