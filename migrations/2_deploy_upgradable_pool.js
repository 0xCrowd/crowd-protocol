const Pool = artifacts.require("v1Pool");
const CRUD = artifacts.require("CRUD");
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function (deployer) {
   await deployer.deploy(CRUD);
   await deployProxy(Pool, "0x891877E6d4047d8e397BF7ed5F12DCe8BAda212f", { deployer, initializer: 'initialize' });
   console.log("Pool:", (await Pool.deployed()).address);
};
