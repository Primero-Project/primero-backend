const { ethers } = require("hardhat");

const main = async () => {
  const Primero = await ethers.getContractFactory("PrimeroMarketplace");
  const primero = await Primero.deploy();
  await primero.deployed();
  console.log("Contract deployed to:", primero.address);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
