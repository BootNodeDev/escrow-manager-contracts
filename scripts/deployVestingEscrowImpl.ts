import { ethers } from "hardhat";
import { deployVestingEscrow, etherscanVerification } from "./helpers/contract";

async function main(): Promise<void> {
  const [deployer] = await ethers.getSigners();

  console.log("\nDeploying VestingEscrow implementation...");
  const impl = await deployVestingEscrow([], deployer);
  console.log("Tx:", impl.deployTransaction.hash);
  await impl.deployed();

  await etherscanVerification(impl.address, []);

  console.log("\nVesting Escrow Implementation Contract: ", impl.address);
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
