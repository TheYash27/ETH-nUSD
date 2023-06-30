const { ethers } = require("hardhat");

async function main() {
  const LoanPool = await ethers.getContractFactory("LoanPool");
  const loanPool = await LoanPool.deploy(
    "ETH/USD Stable Coin",
    "nUSD"
  );
  const nUSDTokenAddress = await loanVault.stablecoin();
  console.log("LoanPool smart contract deployed to: ", loanPool.address);
  console.log("nUSD deployed to: ", nUSDTokenAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
