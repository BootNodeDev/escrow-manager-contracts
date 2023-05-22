import hre from "hardhat";
import { etherscanVerification } from "./helpers/contract";
import { Wallet } from "zksync-web3";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

const pk = process.env.PRIVATE_KEY || "";

async function main(): Promise<void> {
  const wallet = new Wallet(pk);

  console.log("\nDeploying VestingEscrow implementation...");
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("VestingEscrow");
  const impl = await deployer.deploy(artifact, []);
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
