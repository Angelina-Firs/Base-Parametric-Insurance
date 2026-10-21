const hre = require("hardhat");
async function main() {
  const InsuranceFactory = await hre.ethers.getContractFactory("VortexParametricInsurance");
  const insurance = await InsuranceFactory.deploy();
  await insurance.deployed();
  console.log("-> Parametric Insurance Core live at:", insurance.address);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
