import { Address, Deployer } from "../web3webdeploy/types";
import {
  deployOpenxAIClaimer,
  DeployOpenxAIClaimerSettings,
} from "./internal/OpenxAIClaimer";
import { OpenxAI } from "../export/token/OpenxAI";

export interface DeploymentSettings {
  claimerSettings: Partial<DeployOpenxAIClaimerSettings>;
  forceRedeploy?: boolean;
}

export interface Deployment {
  claimer: Address;
}

export async function deploy(
  deployer: Deployer,
  settings?: DeploymentSettings
): Promise<Deployment> {
  if (settings?.forceRedeploy !== undefined && !settings.forceRedeploy) {
    const existingDeployment = await deployer.loadDeployment({
      deploymentName: "claimer.json",
    });
    if (existingDeployment !== undefined) {
      return existingDeployment;
    }
  }

  const claimer = await deployOpenxAIClaimer(deployer, {
    ...{
      token: OpenxAI.address,
      spendingLimit: BigInt(10_000_000) * BigInt(10) ** BigInt(18), // 10M
      spendingPeriod: BigInt(7 * 24 * 60 * 60), // 1 week
      signer: "0xB2834b9001F9E24226172731f34Dc0A6B0940c41",
    },
    ...settings?.claimerSettings,
  });

  await deployer.execute({
    id: "OpenxAIClaimerMintingRole",
    abi: [...OpenxAI.abi],
    to: OpenxAI.address,
    function: "grantRole",
    args: [deployer.viem.keccak256(deployer.viem.toBytes("MINT")), claimer],
  });

  const deployment = { claimer };
  await deployer.saveDeployment({
    deploymentName: "claimer.json",
    deployment: deployment,
  });
  return deployment;
}
