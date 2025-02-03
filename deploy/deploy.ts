import { Address, Deployer } from "../web3webdeploy/types";
import { deployOpenXAI, DeployOpenXAISettings } from "./internal/OpenXAI";
import { deployOpenXAIGenesis, DeployOpenXAIGenesisSettings } from "./internal/OpenXAIGenesis";

export interface DeploymentSettings {
  tokenSettings: DeployOpenXAISettings;
  genesisSettings: Omit<DeployOpenXAIGenesisSettings, "openXAI">;
  forceRedeploy?: boolean;
}

export interface Deployment {
  token: Address;
  genesis: Address;
}

export async function deploy(
  deployer: Deployer,
  settings?: DeploymentSettings
): Promise<Deployment> {
  if (settings?.forceRedeploy !== undefined && !settings.forceRedeploy) {
    const existingDeployment = await deployer.loadDeployment({
      deploymentName: "V1.json",
    });
    if (existingDeployment !== undefined) {
      return existingDeployment;
    }
  }

  const token = await deployOpenXAI(
    deployer,
    settings?.tokenSettings ?? {}
  ).then(deployment => deployment.proxy);
  const genesis = await deployOpenXAIGenesis(deployer, {
    ...(settings?.genesisSettings ?? {USDC: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", rate: BigInt(10)^BigInt(12)}),
    openXAI: token,
  });

  const deployment = { token, genesis };
  await deployer.saveDeployment({
    deploymentName: "V1.json",
    deployment: deployment,
  });
  return deployment;
}
