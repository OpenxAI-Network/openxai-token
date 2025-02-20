import { Address, DeployInfo, Deployer } from "../../web3webdeploy/types";

export interface DeployOpenxAISettings
  extends Omit<DeployInfo, "contract" | "args"> {}

export async function deployOpenxAI(
  deployer: Deployer,
  settings: DeployOpenxAISettings
): Promise<{ implementation: Address; proxy: Address }> {
  const implementation = await deployer
    .deploy({
      id: "OpenxAIImplementation",
      contract: "OpenxAI",
      ...settings,
    })
    .then((deployment) => deployment.address);

  const proxy = await deployer
    .deploy({
      id: "OpenxAIProxy",
      contract: "ERC1967Proxy",
      args: [
        implementation,
        deployer.viem.encodeFunctionData({
          abi: deployer.viem.parseAbi(["function initialize()"]),
          functionName: "initialize",
        }),
      ],
      ...settings,
    })
    .then((deployment) => deployment.address);

  return { implementation, proxy };
}
