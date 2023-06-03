require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.7.6",
  networks:{
    hardhat:{
      forking: {
        url:"https://mainnet.infura.io/v3/081cd96abb24420f90be41985eab04ff",
      },
    },
  },
};
