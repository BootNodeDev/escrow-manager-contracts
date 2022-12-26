import { ethers } from "hardhat";
import { deployFactory, etherscanVerification } from "./helpers/contract";
import { getEnvs } from "./helpers/envs";

async function main(): Promise<void> {
  const [deployer] = await ethers.getSigners();
  const { escrowImpl } = getEnvs();

  console.log("\nDeploying Vesting Escrow Factory...");
  const params = [escrowImpl];
  const factory = await deployFactory(params, deployer);
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
