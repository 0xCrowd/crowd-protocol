const hre = require("hardhat");
const { expect } = require("chai");


describe("Test Factory...", function(){
  let owner;
  let addrs;
  let factory;
  const tokenName = "GOGA";
  const tokenTicker = "GO";
  before("Deploy factory proxy...", async function () {
    // Get Factory contract.
    this.Factory = await hre.ethers.getContractFactory("Factory");
    // Get owner address.
    [owner, ...addrs] = await hre.ethers.getSigners();
    // Deploy updradable Factory.
    factory = await hre.upgrades.deployProxy(this.Factory, [owner.address], 
                                { initializer: 'initialize', kind : 'uups' });
    
    console.log("Factory deployed to:", factory.address);
    console.log("Factory owner:", owner.address);

  });
  it("Check factory owner...", async function () {
    expect(await factory.owner()).to.equal(owner.address);
  });

  it("Check factory initiator...", async function () {
    expect(await factory.initiator()).to.equal(owner.address);
  });
  describe("Test Vault...", function () {
    let vaultAddr;
    let vault;
    before("Create a new Vault with the first deposit == 0.3 ETH...", async function () {
      await factory.newVault(tokenName, tokenTicker, 10, { value: hre.ethers.utils.parseEther("0.3")});
      // Vaults are stored in dynamic array by their serial number, starting with 0.
      // Get the address of the first Vault using the zero index.
      vaultAddr = await factory.getVaultAddress(0);
      // Get the Vault.
      const Vault = await hre.ethers.getContractFactory("Vault");
      vault = await Vault.attach(vaultAddr);
      console.log("Vault initiator before setup:", await vault.initiator())
      // Setup vault initiator using factory as the factory contract if the owner of tha Vault.
      await factory.setupVault(vaultAddr, owner.address);
      console.log("Vault initiator after setup:", await vault.initiator())
      expect(await vault.initiator()).to.equal(owner.address);
    });
    it("Check if the Factory is the owner of the Vault...", async function () {
      expect(await vault.owner()).to.equal(factory.address);
    });
    it("Check user balance...", async function () {
      expect(await vault.getUserDeposit(owner.address)).to.equal("300000000000000000");
    });
    it("Check switch stage to FULL...", async function () {
      await vault.goFullStage();
      // 0 stage - in progress, 1 stage - FULL.
      expect(await vault.stage()).to.equal(1);
    });
    it("Check tokens distribution...", async function (){
        await vault.goFullStage();
        await factory.distributeVaultTokens(vaultAddr);
        expect(await vault.getStake(owner.address)).to.not.equal(0);
    });
    it("Check token name and ticker...", async function (){
        await vault.goFullStage();
        expect(await vault.getTokenName()).to.equal(tokenName);
        expect(await vault.getTokenTicker()).to.equal(tokenTicker);
    });
  });
});


