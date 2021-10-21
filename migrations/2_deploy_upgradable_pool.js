const CRUD = artifacts.require("CRUD");
const DAO = artifacts.require("DAO");
const DAOFactory = artifacts.require("DAOFactory");
const DAOToken = artifacts.require("DAOToken");

const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function (deployer) {
   await deployer.deploy(CRUD);
   await deployer.deploy(DAOFactory, ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"], { deployer, initializer: 'initialize' });
   await deployer.deploy(DAO);
   await deployer.deploy(DAOToken);

   console.log("Factory:", (await DAOFactory.deployed()).address);
   console.log("DAO:", (await DAO.deployed()).address);
};
