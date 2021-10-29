import { assert } from "console";
import hre from "hardhat";

before("Get Factory", async function () {
    this.Factory = await hre.ethers.getContractFactory("DAOFactory");
  });
  
  it("Deploys", async function () {
    const deployedFactory = await hre.upgrades.deployProxy(this.Factory,
      ["0x70997970C51812dc3A010C7d01b50e0d17dc79C8"],
      { initializer: 'initialize' });
  
    assert(await deployedFactory._initiator === "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266");
    
  });