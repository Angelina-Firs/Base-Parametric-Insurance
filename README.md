# Vortex Parametric Insurance

A fully decentralized, oracle-driven parametric insurance protocol built on the Base L2 ecosystem. Vortex provides instant, trustless payouts based on cryptographically verified external data triggers, removing the need for manual claims processing or centralized adjusters.

## Core Mechanics
* **Automated Claims Processing:** Payouts are triggered instantly by whitelisted oracles upon meeting predefined on-chain conditions (e.g., severe weather events, smart contract hacks, or extreme price oracle deviations).
* **Algorithmic Solvency:** The protocol enforces strict liquidity checks before finalizing any payout, ensuring the treasury can securely cover the `payoutWei` without risking systemic insolvency.
* **Transparent Premium Routing:** User premiums are automatically split between the protocol's liquidity pool and the administrative treasury via a hardcoded basis points (BPS) fee structure.

## Architecture
Developed using Solidity `0.8.37`. The smart contract effectively neutralizes reentrancy vectors by utilizing the Checks-Effects-Interactions pattern within the `triggerOraclePayout` execution logic, completely isolating state mutations from ETH transfers.
