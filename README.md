# $DEEP — DeepBlue Token

ERC-20 token powering the [DeepBlue](https://deepbluebase.xyz) ecosystem on **Base**.

## Overview

$DEEP is the utility token for DeepBlue's AI-powered crypto intelligence platform. It token-gates premium API endpoints and enables community airdrops and buyback mechanics through built-in burn support.

## Features

- **ERC-20** standard token on Base L2
- **Owner-controlled minting** — flexible supply management up to max cap
- **Batch airdrop** — send to up to 200 addresses in a single transaction (variable or equal amounts)
- **Batch mint** — mint directly to multiple addresses without pre-funding
- **Burnable** — any holder can burn tokens; enables buyback-and-burn mechanics
- **Token-gated access** — hold 1,000+ $DEEP to unlock DeepBlue premium API endpoints

## Tokenomics

| Parameter | Value |
|-----------|-------|
| Name | DeepBlue |
| Symbol | DEEP |
| Decimals | 18 |
| Max Supply | 1,000,000,000 (1B) |
| Network | Base |
| Contract | TBD (not deployed yet) |

## Gas Costs (Base L2)

| Operation | Estimated Cost |
|-----------|---------------|
| Deploy | ~$0.07 |
| Batch airdrop (200 addresses) | ~$0.33 |

## Tech Stack

- **Solidity** ^0.8.20
- **OpenZeppelin** v5 (ERC20, ERC20Burnable, Ownable)
- **Foundry** for build, test, and deployment

## Project Structure

```
contracts/
  DeepBlueToken.sol    — Token contract
script/
  Deploy.s.sol         — Foundry deployment script
```

## Deploy

```bash
# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts

# Deploy to Base
forge script script/Deploy.s.sol:DeployToken \
  --rpc-url https://mainnet.base.org \
  --broadcast \
  --verify
```

## Links

- Website: [deepbluebase.xyz](https://deepbluebase.xyz)
- Network: [Base](https://base.org)

## License

MIT
