import hre, { ethers } from "hardhat";
import { Contract, Signer } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { VestingEscrow, VestingEscrowFactory } from "../../typechain-types";

export const deployContract = async <ContractType extends Contract>(
  contractName: string,
  args: any[],
  signer?: Signer,
): Promise<ContractType> => {
  return (await (await ethers.getContractFactory(contractName, signer)).deploy(...args)) as ContractType;
};

export const deployVestingEscrow = async (args: any[], signer: SignerWithAddress): Promise<VestingEscrow> => {
  return deployContract("VestingEscrow", args, signer);
};

export const deployFactory = async (args: any[], signer: SignerWithAddress): Promise<VestingEscrowFactory> => {
  return deployContract("VestingEscrowFactory", args, signer);
};

export const etherscanVerification = (
  contractAddress: string,
  args: (string | string[])[],
  exactContractPath?: string,
) => {
  if (hre.network.name === "local" || hre.network.name === "local-ovm") {
    return;
  }

  return runTaskWithRetry(
    "verify:verify",
    {
      address: contractAddress,
      constructorArguments: args,
      contract: exactContractPath,
    },
    4,
    10000,
  );
};

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Retry is needed because the contract was recently deployed and it hasn't propagated to the explorer backend yet
export const runTaskWithRetry = async (task: string, params: any, times: number, msDelay: number) => {
  let counter = times;
  await delay(msDelay);

  try {
    await hre.run(task, params);
  } catch (error) {
    counter--;

    if (counter > 0) {
      await runTaskWithRetry(task, params, counter, msDelay);
    } else {
      let errorMessage = "";
      if (error instanceof Error) {
        errorMessage = error.message;
      }
      console.error("[ETHERSCAN][ERROR]", "unable to verify", errorMessage);
    }
  }
};
