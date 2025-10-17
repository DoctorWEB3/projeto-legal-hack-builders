import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const XAGPriceModule = buildModule("XAGPriceModule", (m) => {
  const xagPriceModule = m.contract("XAGPrice", []);

  return { xagPriceModule };
});

export default XAGPriceModule;
