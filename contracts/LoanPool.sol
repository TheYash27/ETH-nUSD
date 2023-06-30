/**
 * @title Unreal Finance Pre-Interview-Round Assignment
 * @dev This contract allows users to deposit ether (ETH)
 * and receive a stable coin known as nUSD, pegged to the US Dollar,
 *  in return.
 * The amount of nUSD that can be minted against the collateral ETH
 * is determined by the current ETH/USD exchange rate
 * obtained from Chainlink's Sepolia Test-Net Oracle.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./nUSD.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LoanPool is Ownable {
    AggregatorV3Interface internal priceFeed;
    mapping(address => Pool) liqPools;
    MockToken public nUSD;

    struct Pool {
        uint256 nUSDDebt; // The amount of nUSD that was minted against the collateral
        uint256 ETHAmount; // The amount of collateral held by the Pool contract
    }

    event Deposit(uint256 ETHDeposited, uint256 nUSDMinted);
    event Withdraw(uint256 ETHWithdrawn, uint256 nUSDBurned);

    constructor(string memory name, string memory symbol) {
        nUSD = new MockToken(name, symbol);
        priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    /**
     * @dev Retrieves the latest ETH/USD exchange rate from the price feed oracle.
     * @return The latest ETH/USD exchange rate.
     */
    function getETHUSDExchangeRate() public view returns (uint) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint(price);
    }

    /**
     * @notice Allows a user to deposit ETH collateral in exchange for nUSDs.
     * @param ETHToDeposit The amount of Ether the user sent in the transaction.
     */
    function deposit(uint256 ETHToDeposit) external payable {
        require(ETHToDeposit == msg.value, "Uh oh! An incorrect amt. of ETH has been sent along with this Tx.!");
        uint256 nUSDAmountToMint = (ETHToDeposit * getETHUSDExchangeRate()) / (2 * (10 ** 8));
        nUSD.mint(msg.sender, nUSDAmountToMint);
        liqPools[msg.sender].nUSDDebt += nUSDAmountToMint;
        liqPools[msg.sender].ETHAmount += ETHToDeposit;
        emit Deposit(ETHToDeposit, nUSDAmountToMint);
    }

    /**
     * @notice Allows a user to withdraw up to 100% of the collateral they have on deposit.
     * @dev This function cannot allow a user to withdraw more than they deposited.
     * @param nUSDToDeposit The amount of nUSDs that a user is repaying to redeem their collateral.
     */
    function withdraw(uint256 nUSDToDeposit) external {
        require(
            nUSDToDeposit <= liqPools[msg.sender].nUSDDebt,
            "Uh oh! U can NOT deposit more nUSD than U hv. minted against Ur collateral ETH!"
        );
        require(
            nUSD.balanceOf(msg.sender) >= nUSDToDeposit,
            "Uh oh! U do NOT hv. enuf balance of nUSD to send with this Tx.!"
        );
        uint256 ETHAmountToWithdraw = (nUSDToDeposit * (10 ** 8)) / (getETHUSDExchangeRate() * 2);
        nUSD.burn(msg.sender, nUSDToDeposit);
        liqPools[msg.sender].ETHAmount -= ETHAmountToWithdraw;
        liqPools[msg.sender].nUSDDebt -= nUSDToDeposit;
        payable(msg.sender).transfer(ETHAmountToWithdraw);
        emit Withdraw(ETHAmountToWithdraw, nUSDToDeposit);
    }

    /**
     * @notice Retrieves the details of a user's Pool.
     * @param userAddress The address of the Pool owner.
     * @return The amount of nUSD debt and collateral held by the user's Pool.
     */
    function getPool(
        address userAddress
    ) external view returns (uint256, uint256) {
        return (
            liqPools[userAddress].nUSDDebt,
            liqPools[userAddress].ETHAmount
        );
    }

    /**
     * @notice Provides an estimate of how much collateral could be withdrawn for a given amount of nUSDs.
     * @param nUSDAmount The amount of nUSDs that would be repaid.
     * @return The estimated amount of collateral that would be returned.
     */
    function estimateETHAmount(
        uint256 nUSDAmount
    ) external view returns (uint256) {
        return ((nUSDAmount * (10 ** 8)) / getETHUSDExchangeRate());
    }

    /**
     * @notice Provides an estimate of how many nUSDs could be minted at the current rate.
     * @param ETHAmount The amount of ETH that would be deposited.
     * @return The estimated amount of nUSDs that would be minted.
     */
    function estimatenUSDAmount(
        uint256 ETHAmount
    ) external view returns (uint256) {
        return (ETHAmount * getETHUSDExchangeRate()) / (10 ** 8);
    }

    /**
     * @dev Allows the owner to update the price feed oracle.
     * @param _oracle The address of the new price feed oracle.
     */
    function updatePriceFeed() public onlyOwner {
        priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }
}
