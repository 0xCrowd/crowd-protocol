import hre from "hardhat";


async function main() {
  const Factory = await hre.ethers.getContractFactory("Factory");
  console.log("Deploying Factory...");
  let owner;
  let addrs;
  [owner, ...addrs] = await hre.ethers.getSigners();
  const vaultFactory = await hre.upgrades.deployProxy(Factory,
    [owner.address],
    { initializer: 'initialize', kind : 'uups'});
  await vaultFactory.deployed();
  console.log("Factory deployed to:", vaultFactory.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
