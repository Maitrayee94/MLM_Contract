require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.18",
  networks: {
    mainnet: {
      url: process.env.RPC_URL,
      chainid: 56,
      accounts: [process.env.PRIVATE_KEY],
      
    },
  },
  etherscan: {
    apiKey: process.env.BSCSCAN_API_KEY,
  },
};