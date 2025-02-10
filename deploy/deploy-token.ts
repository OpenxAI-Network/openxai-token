import { Address, Deployer } from "../web3webdeploy/types";
import { deployOpenxAI, DeployOpenxAISettings } from "./internal/OpenxAI";

export interface DeploymentSettings {
  tokenSettings: Partial<DeployOpenxAISettings>;
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

  const token = await deployOpenxAI(deployer, {
    ...settings?.tokenSettings,
  }).then((deployment) => deployment.proxy);

  const deployment = { token };
  await deployer.saveDeployment({
    deploymentName: "token.json",
    deployment: deployment,
  });
  return deployment;
}
