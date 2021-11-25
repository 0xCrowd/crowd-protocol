const hre = require("hardhat");
const { expect } = require("chai");


describe("Test Factory...", function(){
  let owner;
  let addrs;
  let factory;
  let mock721;
  let mock1155;
  const tokenName = "GOGA";
  const tokenTicker = "GO";
  before("Deploy factory proxy...", async function () {
    // Get Factory contract.
    this.Factory = await hre.ethers.getContractFactory("Factory");
    Mock721 = await hre.ethers.getContractFactory("Mock721");
    Mock1155 = await hre.ethers.getContractFactory("Mock1155");
    // Get owner address.
    [owner, addr1, addr2, ...addrs] = await hre.ethers.getSigners();
    // Deploy updradable Factory.
    factory = await hre.upgrades.deployProxy(this.Factory, [owner.address], 
                                { initializer: 'initialize', kind : 'uups' });
    mock721 = await Mock721.deploy()
    mock1155 = await Mock1155.deploy()
    await factory.deployed();
    await mock721.deployed();
    await mock1155.deployed();
    console.log("Factory deployed to:", factory.address);
    console.log("Factory owner:", owner.address);
    console.log("Mock721 deployed to:", mock721.address);
    console.log("Mock1155 deployed to:", mock1155.address);
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
    let vaultTokenAddr;
    before("Create a new Vault with the first deposit == 0.3 ETH...", async function () {
      await factory.newVault(tokenName, tokenTicker, 10, { value: hre.ethers.utils.parseEther("0.3")});
      // Vaults are stored in dynamic array by their serial number, starting with 0.
      // Get the address of the first Vault using the zero index.
      vaultAddr = await factory.getVaultAddress(0);
      // Get the Vault.
      const Vault = await hre.ethers.getContractFactory("Vault");
      vault = await Vault.attach(vaultAddr);
      console.log("Vault initiator after setup:", await vault.initiator())
      // Check the owner.
      expect(await vault.initiator()).to.equal(owner.address);
      // Print vault address.
      vaultTokenAddr = await vault.getERC20TokenAddress();
      console.log("Vault Token Address:", vaultTokenAddr)
    });
    it("Check oracle transfer...", async function () {

      const balanceAfter = (await vault.getBalance()-40000).toString();
      await vault.transferToOracle(40000); 
      expect(await vault.getBalance()).to.equal(balanceAfter);
    });
    it("Check if the Factory is the owner of the Vault...", async function () {
      expect(await vault.owner()).to.equal(factory.address);
    });
    it("Check user balance...", async function () {
      expect(await vault.getUserDeposit(owner.address)).to.equal("300000000000000000");
    });
    it("Check switch stage to FULL...", async function () {
      await vault.nextStage();
      // 0 stage - in progress, 1 stage - FULL.
      expect(await vault.stage()).to.equal(1);
    });
    it("Check tokens distribution...", async function (){
      //await vault.nextStage();
      await factory.distributeVaultTokens(vaultAddr);
      expect(await vault.getStake(owner.address)).to.not.equal(0);
    });
    it("Check token name and ticker...", async function (){
      expect(await vault.getERC20TokenName()).to.equal(tokenName);
      expect(await vault.getERC20TokenTicker()).to.equal(tokenTicker);
    });
    it("Check ERC721 operations...", async function (){
      await mock721.awardItem(owner.address, "https://www.tynker.com/minecraft/editor/item/bow/5aa6f77094e01dd76d8b4567?image=true");
      //await mock721.approve(addr1.address, tokenid)
      expect(await mock721.ownerOf(1)).to.equal(owner.address);
      await mock721["safeTransferFrom(address,address,uint256)"](owner.address, vaultAddr, 1);
      expect(await vault.stage()).to.equal(2);
      // Go to ON SALE
      await vault.nextStage();
      expect(await vault.stage()).to.equal(3);
      await vault.setTokenPrice("305000000000000000");
      expect(await vault.getTokenPrice()).to.equal("305000000000000000");
      console.log("Mockaddr:", mock721.address);
      console.log("NFT addr from vault:", await vault.getTokenAddress());
      console.log("Mock owner:", await mock721.ownerOf(1));
      expect(await mock721.ownerOf(1)).to.equal(vaultAddr);
      await vault.tokenToInitiator();
    });
  });
});
