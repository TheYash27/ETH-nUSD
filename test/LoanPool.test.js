const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("LoanPool", function () {
  let loanPool;
  let nUSD;
  let owner;
  let user;

  const ETH_USD_EXCHANGE_RATE = 2000; // Example exchange rate for testing purposes
  const COLLATERAL_AMOUNT = ethers.utils.parseEther("0.02"); // 1 ETH
  const STABLECOIN_AMOUNT = ethers.BigNumber.from(ETH_USD_EXCHANGE_RATE).mul(COLLATERAL_AMOUNT).div(2 * (10 ** 8));

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();
    const LoanPool = await ethers.getContractFactory("LoanPool");
    loanPool = await LoanPool.deploy(
      "ETH/USD Stable Coin",
      "nUSD"
    );
    nUSDAddress = await loanPool.stablecoin();
    nUSD = await ethers.getContractAt("nUSD", nUSDAddress);
  });

  describe("deposit()", function () {
    it("should allow a user to deposit ETH as collateral and receive our nUSD stable coins in return", async function () {
      const tx = await loanPool.connect(user).deposit(COLLATERAL_AMOUNT, {
        value: COLLATERAL_AMOUNT,
      });

      await tx.wait();

      const usernUSDBalance = await nUSD.balanceOf(user.address);
      expect(usernUSDBalance.toString()).to.equal(
        STABLECOIN_AMOUNT.toString()
      );
    });

    it("should revert if the user sends an incorrect amount of ETH", async function () {
      await expect(
        loanPool.connect(user).deposit(COLLATERAL_AMOUNT, {
          value: COLLATERAL_AMOUNT.sub(ethers.utils.parseEther("0.01")),
        })
      ).to.be.revertedWith("Uh oh! An incorrect amt. of ETH has been sent along with this Tx.!");
    });
  });

  describe("withdraw()", function () {
    beforeEach(async function () {
      const tx = await loanPool.connect(user).deposit(COLLATERAL_AMOUNT, {
        value: COLLATERAL_AMOUNT,
      });
      await tx.wait();
    });

    it("should allow a user to withdraw up to 25% of the collateral they have on deposit", async function () {
      const nUSDAmountToRepay = STABLECOIN_AMOUNT.div(2);
      const tx = await nUSD
        .connect(user)
        .approve(loanPool.address, nUSDAmountToRepay);
      await tx.wait();

      const usernUSDBalanceBefore = await user.getBalance();
      const poolBalanceBefore = await ethers.provider.getBalance(
        loanPool.address
      );

      const withdrawTx = await loanPool
        .connect(user)
        .withdraw(nUSDAmountToRepay);
      await withdrawTx.wait();

      const usernUSDBalanceAfter = await user.getBalance();
      const poolBalanceAfter = await ethers.provider.getBalance(
        loanPool.address
      );
      const usernUSDBalance = await nUSD.balanceOf(user.address);
      const userPool = await loanPool.getVault(user.address);

      expect(poolBalanceAfter).to.equal(
        poolBalanceBefore.sub(COLLATERAL_AMOUNT.div(8))
      );
      expect(usernUSDBalance).to.equal(STABLECOIN_AMOUNT.div(2));
      expect(userPool).to.deep.equal([
        STABLECOIN_AMOUNT.div(2),
        (COLLATERAL_AMOUNT.mul(7)).div(8),
      ]);
      expect(usernUSDBalanceAfter).to.be.gt(usernUSDBalanceBefore);
    });

    it("should revert if the user tries to withdraw more stablecoins than they have on deposit", async function () {
      const nUSDAmountToRepay = STABLECOIN_AMOUNT.add(
        ethers.utils.parseEther("0.8001")
      );
      await expect(
        loanPool.connect(user).withdraw(nUSDAmountToRepay)
      ).to.be.revertedWith("Uh oh! U can NOT deposit more nUSD than U hv. minted against Ur collateral ETH!");
    });

    it("should revert if the user tries to withdraw more collateral than they have on deposit", async function () {
      const nUSDAmountToRepay = STABLECOIN_AMOUNT.mul(5);
      const tx = await nUSD
        .connect(user)
        .approve(loanPool.address, nUSDAmountToRepay);
      await tx.wait();

      await expect(
        loanPool.connect(user).withdraw(nUSDAmountToRepay)
      ).to.be.revertedWith("Uh oh! U do NOT hv. enuf balance of nUSD to send with this Tx.!");
    });
  });
});
