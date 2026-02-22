# Real-World Asset Tokenization Platform

This is a Real-World Asset (RWA) tokenization platform built with Solidity, ERC1155, and Hardhat.

A RWA Tokenization Platform is a digital infrastructure that enables the conversion of physical or traditional financial assets, such as real estate, bonds, commodities, or art—into blockchain-based digital tokens. These platforms bridge traditional finance (TradFi) with decentralized finance (DeFi), allowing for fractional ownership, real-time settlement, global access, and enhanced liquidity.

## Project Overview

This project demonstrates a full on-chain lifecycle for real-world assets:

- Asset tokenization using ERC1155 (fractional ownership)
- Factory pattern for user-specific asset contracts
- On-chain auctions for asset fractions
- Ownership transfer & resale support

The codebase is intentionally structured to reflect production-grade smart contract design..

## Architecture

Core Contracts

1. RWAAssetFactory.sol:
    - Factory pattern for asset deployment
    - Each user gets one dedicated asset contract
    - Tracks deployed asset contracts
    - Enables clean indexing and isolation
2. RWAAsset.sol:
    - ERC1155-based fractional asset model
    - Each asset ID represents a real-world asset
    - Fractions are minted to owners
    - Metadata stored per asset ID
    - Ownership is balance-based, not role-based
3. RWAAuction.sol: Valid asset holders can auction their fractions for sell.
    - Auctions fractions of any ERC1155-compatible asset
    - Uses safeTransferFrom to escrow fractions
    - Highest-bidder-wins model
    - Supports secondary auctions (design-dependent)
    - Enforces ERC1155 approval rules strictly
### Important Design Decision
ERC1155 Approval Requirement: The auction contract requires explicit approval from the current token holder.

## Asset Lifecycle
Deploy Asset → Mint Fractions → Approve Auction
     ↓
Start Auction → Place Bids → End Auction
     ↓
Fractions Transferred → New Owner Can Re-Auction

## What Is Tested?
1. Factory Tests
    - One asset contract per user
    - Duplicate deployments prevented
    - Correct asset tracking
      
2. Asset Tests
    - Only owner can mint fractions
    - ERC1155 balances behave correctly
    - Metadata storage

3. Auction Tests
    - Auction creation rules
    - Approval enforcement
    - Bid handling & refunds
    - Time-based auction ending
    - Fraction transfer on succes
    - ETH transfer to seller
    - Secondary owner auction capability


## Tech Stack 
- Solidity ^0.8.x
- OpenZeppelin Contracts (ERC1155)
- Hardhat
- Ethers.js v6
- Mocha + Chai
