import { Address, Deployer } from "../web3webdeploy/types";
import { deployOpenXAI, DeployOpenXAISettings } from "./internal/OpenXAI";

export interface DeploymentSettings {
  tokenSettings: Partial<DeployOpenXAISettings>;
  forceRedeploy?: boolean;
}

export interface Deployment {
  token: Address;
}

export async function deploy(
  deployer: Deployer,
  settings?: DeploymentSettings
): Promise<Deployment> {
  if (settings?.forceRedeploy !== undefined && !settings.forceRedeploy) {
    const existingDeployment = await deployer.loadDeployment({
      deploymentName: "token.json",
    });
    if (existingDeployment !== undefined) {
      return existingDeployment;
    }
  }

  const token = await deployOpenXAI(deployer, {
    ...settings?.tokenSettings,
  }).then((deployment) => deployment.proxy);

  const deployment = { token };
  await deployer.saveDeployment({
    deploymentName: "token.json",
    deployment: deployment,
  });
  return deployment;
}
