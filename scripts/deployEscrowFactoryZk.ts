import hre from "hardhat";
import { etherscanVerification } from "./helpers/contract";
import { getEnvs } from "./helpers/envs";
import { Wallet } from "zksync-web3";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

const pk = process.env.PRIVATE_KEY || "";

async function main(): Promise<void> {
  const wallet = new Wallet(pk);

  const { escrowImpl } = getEnvs();

  console.log("\nDeploying Vesting Escrow Factory...");
  const deployer = new Deployer(hre, wallet);
  const params = [escrowImpl];
  const artifact = await deployer.loadArtifact("VestingEscrowFactory");
  const factory = await deployer.deploy(artifact, params);
  console.log("Tx:", factory.deployTransaction.hash);
  await factory.deployed();

  await etherscanVerification(factory.address, params);

  console.log("\nVesting Escrow Factory Contract: ", factory.address);
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
