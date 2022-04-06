
const hre = require("hardhat");

async function main() {
  const luckyLandFactory = await hre.ethers.getContractFactory("LuckyLandFactory");
  const luckyLand = await luckyLandFactory.deploy();

  await luckyLand.deployed();

  console.log("luckyLandFactory deployed to:", luckyLand.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });