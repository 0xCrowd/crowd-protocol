const Pool = artifacts.require("Pool");
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function (deployer) {
   await deployProxy(Pool, "0x891877E6d4047d8e397BF7ed5F12DCe8BAda212f", { deployer, initializer: 'initialize' });
   console.log("Pool:", (await Pool.deployed()).address);
};
