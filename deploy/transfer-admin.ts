import { OpenxAIContract } from "../export/token/OpenxAI";
import { Deployer } from "../web3webdeploy/types";

export async function deploy(deployer: Deployer) {
  const multisigAddress = "0x1807f6f41c8f7E886E3D325F5fb1F496446D4bCc";

  await deployer.execute({
    id: "OpenxAIMultisigAdminRole",
    abi: [...OpenxAIContract.abi],
    to: OpenxAIContract.address,
    function: "grantRole",
    args: [deployer.viem.zeroHash, multisigAddress],
    from: "0x3e166454c7781d3fD4ceaB18055cad87136970Ea",
  });
}
