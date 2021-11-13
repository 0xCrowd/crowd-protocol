import hre from "hardhat";


async function main(): Promise<void> {
  const Factory = await hre.ethers.getContractFactory("Factory");
  console.log("Deploying Factory...");
  let owner;
  let addrs;
  [owner, ...addrs] = await hre.ethers.getSigners();
  const vaultFactory = await hre.upgrades.deployProxy(Factory,
    ["0x05d7473bF52920f925F4b8d9048409a88Bb4B562"],
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
