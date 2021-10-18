// Load dependencies
const { expect } = require('chai');
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
 
// Load compiled artifacts
const Pool = artifacts.require('v1Pool');
 
// Start test block
contract('v1Pool (proxy)', function () {
  beforeEach(async function () {
    // Deploy a new Box contract for each test
    this.pool = deployProxy(Pool, "0x891877E6d4047d8e397BF7ed5F12DCe8BAda212f", { deployer, initializer: 'initialize' });
  });
 
  // Test case
  it('retrieve returns a value previously initialized', async function () {
    // Test if the returned value is the same one
    // Note that we need to use strings to compare the 256 bit integers
    expect((await this.pool.initializer).toString()).to.equal("0x891877E6d4047d8e397BF7ed5F12DCe8BAda212f");
  });
});