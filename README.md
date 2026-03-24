# DeepBlueBase Token ($DBB)

ERC-20 token on Base. Powers DeepBlue — an autonomous AI agent company covering $200/month Claude Max cost with revenue.

## Contracts

| Contract | Description |
|----------|-------------|
| `DeepBlueToken.sol` | $DBB token: 10M supply, 1% transfer fee → treasury, fee-exempt whitelist |
| `DeepBlueFarm.sol` | Synthetix-style LP staking: stake Uniswap LP tokens, earn $DBB rewards |

## Tokenomics

| Allocation | Amount | % |
|------------|--------|---|
| LP Farming Rewards | 3,000,000 | 30% |
| Airdrops | 2,000,000 | 20% |
| Treasury | 3,000,000 | 30% |
| Initial Liquidity | 1,000,000 | 10% |
| Reserve | 1,000,000 | 10% |

## Token Features

- **1% transfer fee** on trades → treasury wallet (auto-funds operations)
- **Fee-exempt whitelist**: treasury, LP pool, team (no double-dip)
- **MAX_FEE_RATE**: 5% hard cap (safety)
- **Batch airdrop**: distribute to thousands of wallets in one tx
- **Mint / burn**: owner-controlled supply management

## Farm Features

- **Synthetix StakingRewards pattern** (battle-tested, gas-efficient)
- Stake Uniswap V3 DBB/ETH LP tokens
- Earn $DBB proportional to your share of total staked LP
- `stake(amount)` / `withdraw(amount)` / `claimReward()` / `exit()`
- Owner funds reward periods: `notifyRewardAmount(reward, duration)`
- Pause/unpause and emergency ERC-20 recovery

## Deployment (Base Mainnet)

```bash
# Compile with Foundry
forge build

# Deploy token
forge script script/Deploy.s.sol --rpc-url https://mainnet.base.org --broadcast

# Constructor args: (totalSupply, owner, treasury)
# totalSupply: 10_000_000e18 (10M tokens)
# owner: deployer EOA
# treasury: 0x47ffc880cfF2e8F18fD9567faB5a1fBD217B5552
```

## Architecture

```
$DBB Token (DeepBlueToken.sol)
  → Users trade on Uniswap V3 (DBB/ETH pool on Base)
  → 1% fee per trade → treasury wallet
  → Treasury funds bot operations (Claude API, servers)

LP Farm (DeepBlueFarm.sol)
  → Users add DBB+ETH liquidity on Uniswap → get LP tokens
  → Stake LP tokens in farm → earn $DBB rewards
  → 3M DBB allocated for 12-month reward period
```

## Token-Gated API

Hold 100+ $DBB → premium tier on [api.deepbluebase.xyz](https://api.deepbluebase.xyz):
- **Free tier**: 100 req/day
- **Premium tier**: 10,000 req/day + all endpoints

## Links

- Website: [deepbluebase.xyz](https://deepbluebase.xyz)
- API: [api.deepbluebase.xyz](https://api.deepbluebase.xyz)
- Farm: [deepbluebase.xyz/farm](https://deepbluebase.xyz/farm)
- Wallet: `0x47ffc880cfF2e8F18fD9567faB5a1fBD217B5552` (Base)

## License

MIT
