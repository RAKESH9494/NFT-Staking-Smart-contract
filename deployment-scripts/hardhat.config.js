require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');

/** @type import('hardhat/config').HardhatUserConfig */

module.exports = {
  solidity: "0.8.24",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    testnet: {
      url: API_URL, //API key should get from the providers like Alchemy, infura etc.
      accounts: [`0x${PRIVATE_KEY}`] // Private key of the owner's address
    }
  },
}


