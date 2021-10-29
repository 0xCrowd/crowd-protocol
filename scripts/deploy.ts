//import { assert } from "console";
import hre from "hardhat";


async function main() {
  const Factory = await hre.ethers.getContractFactory("DAOFactory");
  console.log("Deploying Factory...");
  const daoFactory = await hre.upgrades.deployProxy(Factory,
    ["0x70997970C51812dc3A010C7d01b50e0d17dc79C8"],
    { initializer: 'initialize', kind : 'uups'});
  console.log("Factory deployed to:", daoFactory.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });



/*
before("Get Factory", async function () {
  this.Factory = await hre.ethers.getContractFactory("DAOFactory");
});

it("Deploys", async function () {
  const deployedFactory = await hre.upgrades.deployProxy(this.Factory,
    ["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"],
    { initializer: 'initialize' });

  assert(await deployedFactory.owner === "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266");
  
});
*/