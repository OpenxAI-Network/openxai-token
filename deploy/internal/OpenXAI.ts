import { Address, DeployInfo, Deployer } from "../../web3webdeploy/types";

export interface DeployOpenXAISettings
  extends Omit<DeployInfo, "contract" | "args"> {}

export async function deployOpenXAI(
  deployer: Deployer,
  settings: DeployOpenXAISettings
): Promise<{ implementation: Address, proxy: Address}> {
  const implementation = await deployer
  .deploy({
    id: "OpenXAI Implementation",
    contract: "OpenXAI",
    ...settings,
  })
  .then((deployment) => deployment.address);

  const proxy = await  deployer
  .deploy({
    id: "OpenXAI Proxy",
    contract: "ERC1967Proxy",
    args: [deployer.viem.encodeFunctionData({
      abi: deployer.viem.parseAbi(["function initialize()"]),
      functionName: "initialize"
    })],
    ...settings,
  })
  .then((deployment) => deployment.address);;

  return { implementation, proxy };
}
