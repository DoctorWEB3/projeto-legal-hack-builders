import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const BondSeizureManagerModule = buildModule("BondSeizureManagerModule", (m) => {
  const tokenMinting = m.getParameter("tokenMinting", "0x3AAf0eE4853d1f002fE92bf6974582857f43270C");
  const subsequentMarket = m.getParameter("subsequentMarket", "0x6A5666c36da84213C9b619637BEC6BAf3dA9664b");
  const escrow = m.getParameter("escrow", "0x551A14E87A4fc950f8614fde917b6978d46675b1");


  const bondSeizureManagerModule = m.contract("BondSeizureManager", [tokenMinting, subsequentMarket, escrow]);

  return { bondSeizureManagerModule };
});

export default BondSeizureManagerModule;
