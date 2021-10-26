const HDWalletProvider = require("@truffle/hdwallet-provider");
const mnemonic = process.env["STAGE_MNEMONIC"];
const stage_endpoint = process.env["STAGE_ENDPOINT"];

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*"
    },
    stage: {
      provider: function() {
        return new HDWalletProvider(mnemonic, stage_endpoint)
      },
      network_id: 31337
    }
  },
  compilers: {
    solc: {
      version:"^0.8.0",
      docker: false, // Use a version obtained through docker
      parser: "solcjs",  // Leverages solc-js purely for speedy parsing
    }
  }
};
