import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify"; // Etherscan plugin
import dotenv from "dotenv";
dotenv.config();

if (!process.env.INFURA_URL || !process.env.PRIVATE_KEY || !process.env.ETHERSCAN_API_KEY) {
  throw new Error("Defina INFURA_URL, PRIVATE_KEY e ETHERSCAN_API_KEY no .env");
}

const config: HardhatUserConfig = {
  solidity: "0.8.29",
  networks: {
    amoy: {
      type: "http",
      url: process.env.INFURA_URL!,
      chainId: parseInt(process.env.CHAIN_ID || "80002"),
      accounts: [process.env.PRIVATE_KEY!],
    },
  },
} as any; // <- força o TS aceitar propriedades extras

// Adiciona os plugins
(config as any).etherscan = {
  apiKey: process.env.ETHERSCAN_API_KEY!,
  customChains: [
    {
      network: "amoy",
      chainId: 80002,
      urls: {
        apiURL: "https://api-amoy.polygonscan.com/api",
        browserURL: "https://amoy.polygonscan.com",
      },
    },
  ],
};

export default config;
