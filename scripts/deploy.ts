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
