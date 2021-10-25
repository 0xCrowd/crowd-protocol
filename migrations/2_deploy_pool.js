const DAOFactory = artifacts.require("DAOFactory");

module.exports = async function (deployer) {
   await deployer.deploy(DAOFactory, "0x8b88b18F79A4548738009fe6817BDB375D1e437b", "0x000582E365fEAcd919C1FFaAfF2616476eDf64c7");
   const dao_factory = await DAOFactory.deployed();
   console.log("Factory:", dao_factory.address);
};
