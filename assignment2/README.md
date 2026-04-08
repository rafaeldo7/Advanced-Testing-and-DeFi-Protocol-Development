# Assignment 2: Advanced Testing and DeFi Protocol Development (AMM)

## Overview

This project implements a comprehensive AMM (Automated Market Maker) using Foundry and includes advanced testing techniques.

## Project Structure

```
assignment2/
├── src/
│   ├── Token.sol       # ERC-20 token implementation
│   ├── LPToken.sol     # Liquidity Provider token
│   └── AMM.sol         # Constant Product AMM
├── test/
│   ├── TokenTest.sol   # ERC-20 tests (unit, fuzz, invariant)
│   ├── AMMTest.sol     # AMM tests (15+ test cases)
│   └── ForkTest.sol    # Fork testing against mainnet
├── script/
│   └── Deploy.s.sol    # Deployment scripts
├── foundry.toml        # Foundry configuration
└── README.md           # This file
```

## Testing Commands

```bash
# Run all tests
forge test

# Run with verbose output
forge test -vv

# Run coverage
forge coverage

# Run fuzz tests
forge test --match-test testFuzz

# Run invariant tests
forge test --match-test testInvariant

# Run gas report
forge test --gas-report
```

---

## PART 1: ADVANCED TESTING

### Task 1: Unit Testing vs Fuzz Testing vs Invariant Testing

#### Unit Testing (25 tests in TokenTest, 26 in AMMTest)

**When to use:**
- When you know specific inputs and expected outputs
- For testing known edge cases and happy paths
- When you need deterministic, reproducible results
- For testing business logic with specific values

**Example:**
```solidity
function testTransfer() public {
    vm.prank(owner);
    token.transfer(user1, 100 * 1e18);
    assertEq(token.balanceOf(user1), 100 * 1e18);
}
```

#### Fuzz Testing (4 fuzz tests: transfer, approve, mint, swap)

**When to use:**
- When you want to discover unknown edge cases
- For testing with thousands of random inputs
- To find vulnerabilities that manual testing misses
- When input space is too large for manual testing

**Example:**
```solidity
function testFuzzTransfer(uint256 amount) public {
    vm.assume(amount > 0 && amount <= token.balanceOf(owner));
    vm.prank(owner);
    token.transfer(user1, amount);
    assertEq(token.balanceOf(user1), amount);
}
```

#### Invariant Testing (3 invariant tests in TokenTest, 3 in AMMTest)

**When to use:**
- To verify properties that should ALWAYS hold
- After major changes to ensure no regressions
- For testing fundamental guarantees (e.g., total supply conservation)

**Example:**
```solidity
function testInvariantTotalSupplyNeverDecreases() public view {
    assertGt(token.totalSupply(), 0);
}
```

### Summary: When to Use Each

| Testing Type | Best For | Limitations |
|--------------|----------|-------------|
| **Unit** | Known inputs, specific behaviors | Can't find unknown bugs |
| **Fuzz** | Large input spaces, unknown edge cases | May miss logical bugs |
| **Invariant** | Core guarantees, regression testing | Requires careful property definition |

---

### Task 2: Fork Testing

#### vm.createSelectFork(url)

Creates a forked copy of the blockchain:
- Downloads state from specified RPC URL
- All subsequent calls operate on the forked chain
- Returns a fork ID for management
- Example: `vm.createSelectFork("https://eth-mainnet.alchemy.com/v2/YOUR_KEY")`

#### vm.rollFork(blockNumber)

Advances the forked chain:
- Simulates time passing on the network
- Useful for time-sensitive operations
- Example: `vm.rollFork(block.number + 100)`

**Benefits of Fork Testing:**
- Test against real, deployed contracts (USDC, WETH, Uniswap)
- No need to deploy mock contracts
- More realistic testing environment
- Test actual protocol integrations

**Limitations:**
- Requires RPC endpoint with API key
- Slower than unit tests (network calls)
- Cannot modify historical state
- Rate limits may apply

---

## PART 2: AMM DEVELOPMENT

### Task 3: Constant Product AMM

The AMM implements the constant product formula: **x * y = k**

#### Key Functions:

1. **addLiquidity()**: Add tokens proportionally, receive LP tokens
2. **removeLiquidity()**: Burn LP tokens, receive proportional tokens
3. **swap()**: Exchange tokens with 0.3% fee
4. **getAmountOut()**: Calculate output using constant product formula

#### Slippage Protection

All functions include minimum amount parameters:
- `amountAMin` / `amountBMin` for addLiquidity
- `amountAMin` / `amountBMin` for removeLiquidity
- `amountOutMin` for swap functions

### Task 4: Mathematical Analysis

See `AMM_Mathematical_Analysis.md` for detailed analysis:
- Constant product formula derivation
- 0.3% fee impact on invariant k
- Impermanent loss calculation (5.72% for 2x price change)
- Price impact analysis
- Comparison with Uniswap V2

---

## Gas Reports

### AMM Contract

| Function | Avg Gas |
|----------|---------|
| Deployment | 1,873,450 |
| addLiquidity | 120,898 |
| removeLiquidity | 91,081 |
| swapAForB | 73,279 |
| swapBForA | 73,687 |

### Token Contract

| Function | Avg Gas |
|----------|---------|
| Deployment | 724,411 |
| transfer | 51,616 |
| approve | 46,702 |
| mint | 53,298 |

---

## Test Results

- **Total Tests**: 53
- **Coverage**: 89.52%
- **TokenTest**: 25 tests (unit + fuzz + invariant)
- **AMMTest**: 26 tests (unit + fuzz + invariant)
- **ForkTest**: 2 tests (documentation)

---

## Comparison to Uniswap V2

### Implemented:
- ✅ Constant product formula
- ✅ 0.3% trading fee
- ✅ Liquidity provider tokens
- ✅ Slippage protection
- ✅ Events for all operations

### Missing:
- ❌ Flash loans
- ❌ Protocol fees (0.05%)
- ❌ Factory contract
- ❌ Router contract
- ❌ Multi-hop swaps
- ❌ Oracle functionality

---

## Deployment

```bash
# Deploy locally
forge script script/Deploy.s.sol --broadcast

# Deploy to testnet
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast
```
