# Blockchain Technologies 2 - Assignment 2

## Advanced Testing and DeFi Protocol Development (AMM)

### Project Structure

```
.
├── src/
│   ├── Token.sol          # ERC-20 implementation
│   ├── TokenA.sol         # Test token A
│   ├── TokenB.sol         # Test token B
│   ├── LPToken.sol        # Liquidity Provider token
│   └── AMM.sol            # Constant Product AMM
├── test/
│   ├── TokenTest.sol      # ERC-20 tests (unit, fuzz, invariant)
│   ├── ForkTest.sol       # Fork testing against mainnet
│   └── AMMTest.sol        # AMM tests (15+ test cases)
├── script/
│   └── Deploy.s.sol       # Deployment script
├── docs/
│   ├── AMM_Mathematical_Analysis.md
│   ├── Fuzz_Testing_Explanation.md
│   └── Fork_Testing_Explanation.md
├── foundry.toml           # Foundry configuration
├── remappings.txt         # Import remappings
└── README.md
```

---

## Part 1: Advanced Testing with Foundry

### Task 1: Foundry Project Setup & Fuzz Testing

**Files:**
- `test/TokenTest.sol` - Complete test suite

**Test Coverage:**
- 15+ Unit tests covering: mint, transfer, approve, transferFrom, edge cases
- Fuzz tests for transfer and approve functions
- Invariant tests (total supply constant, no address exceeds total supply)

**Run tests:**
```bash
forge test
```

**Run with coverage:**
```bash
forge coverage
```

### Task 2: Fork Testing Against Mainnet

**Files:**
- `test/ForkTest.sol` - Fork testing suite

**Tests:**
- Read USDC total supply from mainnet
- Simulate Uniswap V2 swap quotes
- Multi-hop swap quotes
- Price impact analysis

**Setup:**
```bash
export MAINNET_RPC_URL="https://mainnet.infura.io/v3/YOUR_KEY"
forge test --match-test Fork
```

---

## Part 2: AMM Development

### Task 3: Constant Product AMM

**Smart Contract Features:**
- ✅ Accept two ERC-20 tokens as trading pair
- ✅ addLiquidity() - deposit tokens proportionally, receive LP tokens
- ✅ removeLiquidity() - burn LP tokens, receive back tokens
- ✅ swap() - swap tokens with 0.3% fee
- ✅ getAmountOut() - constant product formula
- ✅ Events: LiquidityAdded, LiquidityRemoved, Swap
- ✅ Slippage protection (minAmountOut parameter)

**Test Coverage (18 tests):**
- Add liquidity (first provider, subsequent providers)
- Remove liquidity (partial, full)
- Swap both directions
- K increases after swaps (fees)
- Slippage protection
- Edge cases (zero amounts, price impact)
- Fuzz tests

**Run AMM tests:**
```bash
forge test --match-contract AMMTest
```

### Task 4: Mathematical Analysis

**Document:** `docs/Mathematical_Analysis.md`

Covers:
- Constant Product Formula derivation (x * y = k)
- Output amount formula with 0.3% fee
- Invariant k analysis before/after trades
- Impermanent Loss derivation with formula and examples
- Price Impact calculation
- LP Token issuance and withdrawal math
- Security analysis
- Comparison with Uniswap V2

Covers:
- Derivation of constant product formula
- 0.3% fee effect on invariant k
- Impermanent loss derivation and calculation for 2x price change
- Price impact as function of trade size
- Comparison with Uniswap V2

---

## Running the Project

### Install Dependencies

```bash
# Install forge-std
git submodule add https://github.com/foundry-rs/forge-std lib/forge-std
```

### Run All Tests

```bash
forge test -vv
```

### Run Specific Test Suites

```bash
# Token tests
forge test --match-contract TokenTest

# Fork tests (requires MAINNET_RPC_URL)
forge test --match-contract ForkTest

# AMM tests
forge test --match-contract AMMTest
```

### Gas Report

```bash
forge gas
```

---

## Environment Variables

Create `.env` file:

```bash
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_KEY
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
ETHERSCAN_API_KEY=your_etherscan_key
PRIVATE_KEY=your_private_key
```

---

## Documentation

- `docs/Fuzz_Testing_Explanation.md` - Fuzz vs Unit testing comparison
- `docs/Fork_Testing_Explanation.md` - Fork testing benefits/limitations
- `docs/AMM_Mathematical_Analysis.md` - Technical AMM analysis

---

## Summary

This project demonstrates:

1. **Advanced Testing**: Unit tests, fuzz tests, invariant tests, fork tests
2. **AMM Implementation**: Full constant product market maker
3. **Mathematical Analysis**: Deep dive into AMM mechanics
4. **Best Practices**: Comprehensive testing, documentation, gas optimization

All smart contracts are written in Solidity 0.8.20 and tested with Foundry.
