const AddressSet = artifacts.require("AddressSet");
const UintSet = artifacts.require("UintSet");
const Pool = artifacts.require("Pool");

module.exports = async function (deployer) {
   await deployer.deploy(Pool, "0x891877E6d4047d8e397BF7ed5F12DCe8BAda212f");
   console.log("Pool:", (await Pool.deployed()).address);
};