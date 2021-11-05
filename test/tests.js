const hre = require("hardhat");
const { expect } = require("chai");
const { factory } = require("typescript");


describe("Test Factory:", function(){
  let owner;
  let addrs;
  beforeEach("Deploy factory proxy...", async function () {
    // Get addresses.
    this.Factory = await hre.ethers.getContractFactory("Factory");
    [owner, ...addrs] = await hre.ethers.getSigners();
    // Deploy updradable Factory.
    const factory = await hre.upgrades.deployProxy(this.Factory, [owner.address], 
                                { initializer: 'initialize', kind : 'uups' });
    await factory.deployed();
    console.log("Factory deployed to:", factory.address);

  });
  it("Check factory owner...", async function () {

    console.log("ЖОПА");
    expect(await factory.owner()).to.equal(owner.address);
  });
  it("Check factory initiator...", async function () {
    expect(factory.initiator()).to.equal(owner.address);
  });
  it("Check Vault...", async function () {
    console.log("Create a new Vault with the first deposit == 0.3 ETH...");
    await factory.newVault("GOGA", "GO", 10, { value: hre.ethers.utils.parseEther("0.3")});
    // The first Vault has index 0.
    const vaultAddr = await factory.getVaultAddress(0);
    // Get the Vault.
    const Vault = await hre.ethers.getContractFactory("Vault");
    const vault = await Vault.attach(vaultAddr);
    console.log("Check if the factory is the owner of the Vault...");
    expect(await vault.owner().to.equal(factory.address));
    console.log("Check initiator setup for the vault...", vault.initiator());
    //expect(await vault.initiator().to.equal);
    await factory.setupVault(vaultAddr, owner.address);
    expect(await vault.owner().to.equal(owner.address));
    console.log("Check token name...");
    expect(await vault.getTokenName().to.equal("GOGA"));
    console.log("Check token ticket...");
    expect(await vault.getTokenTicket().to.equal("GO"));
    console.log("Check token ticket...");


    


  });
})

