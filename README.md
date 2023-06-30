# LoanVault

This contract allows users to deposit ether (ETH) and receive a stable coin known as nUSD, pegged to the US Dollar, in return.
The amount of nUSD that can be minted against the collateral ETH is determined by the current ETH/USD exchange rate obtained from Chainlink's Sepolia Test-Net Oracle.

### Key Functions

- `deposit`: Allows a user to deposit ETH collateral in exchange for stablecoins. The amount of stablecoins that can be minted is determined by the current ETH/USD exchange rate obtained from an oracle.
- `withdraw`: Allows a user to withdraw up to 100% of the collateral they have on deposit. The amount of collateral that can be withdrawn is determined by the current ETH/USD exchange rate obtained from an oracle. This function cannot allow a user to withdraw more than they deposited.
- `getPool`: Retrieves the details of a user's vault, including the amount of stablecoin debt and collateral held by the user's vault.
- `estimateETHAmount`: Provides an estimate of how much collateral could be withdrawn for a given amount of stablecoins.
- `estimatenUSDAmount`: Provides an estimate of how many stablecoins could be minted at the current rate.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```
