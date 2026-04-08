# AMM Mathematical Analysis

## 1. Constant Product Formula Derivation

### 1.1 The Basic Formula

The constant product AMM follows the formula:

```
x * y = k
```

Where:
- `x` = reserve of token A
- `y` = reserve of token B  
- `k` = constant product (invariant)

### 1.2 Why It Works

The formula works because of the following properties:

1. **Always provides liquidity**: As long as both reserves > 0, the formula guarantees that any input of token A will always produce some output of token B.

2. **Price automatically adjusts**: The price of token A in terms of token B is `y/x`. When someone buys A (decreasing x, increasing y), the price of A increases automatically.

3. **No order book needed**: The AMM acts as an automated market maker that always quotes a price based on current reserves.

### 1.3 Mathematical Proof

Starting with the invariant:
```
x * y = k
```

After a trade where `Δx` of token A is added:
```
(x + Δx) * y' = k
```

Solving for output `Δy`:
```
y' = k / (x + Δx)
Δy = y - y' = y - k/(x + Δx)
```

Substituting `k = x * y`:
```
Δy = y - (x * y)/(x + Δx)
Δy = y * (1 - x/(x + Δx))
Δy = y * (Δx / (x + Δx))
Δy = (y * Δx) / (x + Δx)
```

This is the classic AMM swap formula.

---

## 2. Effect of 0.3% Fee on the Invariant

### 2.1 Fee Implementation

Our AMM charges a 0.3% fee on each trade. The fee is deducted from the input amount before the swap:

```
amountInWithFee = amountIn * (10000 - 30) / 10000 = amountIn * 0.997
```

### 2.2 How Fee Affects k

Without fees, `k` remains exactly constant:
```
x * y = k (before and after trade)
```

With fees, `k` **increases** after each trade:
```
(x + fee) * y' = k_new > k
```

The 0.3% fee stays in the pool as liquidity, which:
- Increases the constant product `k`
- Benefits liquidity providers (they earn from fees)
- Makes the pool more valuable over time

### 2.3 Numerical Example

Initial state: `x = 1000, y = 1000, k = 1,000,000`

Trade: Swap 100 A for B (with 0.3% fee)

```
Fee = 100 * 0.003 = 0.3
amountInWithFee = 100 - 0.3 = 99.7

Output = y * amountInWithFee / (x + amountInWithFee)
Output = 1000 * 99.7 / (1000 + 99.7) = 90.61

New reserves: x = 1099.7, y = 909.39
New k = 1099.7 * 909.39 = 999,999.6 ≈ 1,000,000 (increased slightly)
```

---

## 3. Impermanent Loss

### 3.1 Definition

Impermanent Loss (IL) occurs when the price ratio between two tokens in an AMM changes differently than when you deposited them. It's called "impermanent" because it only becomes permanent when you withdraw.

### 3.2 Derivation

Let:
- `P₀` = initial price ratio (A/B) at deposit time
- `P₁` = final price ratio (A/B) at withdrawal time
- `x₀, y₀` = initial reserves
- `x₁, y₁` = final reserves

For equal value deposit:
```
x₀ = y₀ (at initial price P₀ = 1)
```

If price changes to `P₁`, the AMM rebalances:
```
x₁ = sqrt(k / P₁)
y₁ = sqrt(k * P₁)
```

Value in token A terms at end:
```
V_AMM = x₁ + y₁ / P₁
V_HOLD = x₀ + y₀ / P₁
```

### 3.3 IL for 2x Price Change

Let's calculate IL when one token doubles in value (2x price change):

**Scenario**: Token A doubles in value (price goes from 1 to 2)

Initial: `x₀ = y₀ = 1000` (each worth $1000)
Final (without trading): `x = y = 1000` (but now x is worth $2000)

**With AMM:**
```
x₁ = sqrt(1,000,000 / 2) = sqrt(500,000) = 707.11
y₁ = sqrt(1,000,000 * 2) = sqrt(2,000,000) = 1414.21

Value in A = 707.11 + 1414.21 / 2 = 707.11 + 707.11 = 1414.21
```

**Without AMM (HODL):**
```
Value = 1000 + 1000 / 2 = 1500
```

**Impermanent Loss:**
```
IL = (1414.21 - 1500) / 1500 = -5.72%
```

### 3.4 General IL Formula

For price ratio change of `r`:
```
IL = 2 * sqrt(r) / (1 + r) - 1
```

| Price Change | IL |
|--------------|-----|
| 1.25x | -0.6% |
| 1.5x | -2.0% |
| 2x | -5.7% |
| 3x | -13.4% |
| 5x | -25.5% |

---

## 4. Price Impact

### 4.1 Definition

Price impact is how much the swap changes the effective price of the token being bought.

### 4.2 Formula

From the constant product formula:
```
output = (input * reserveOut) / (reserveIn + input)
```

The **effective price** is:
```
effectivePrice = output / input = reserveOut / (reserveIn + input)
```

### 4.3 Price Impact as Function of Trade Size

```
priceImpact = (spotPrice - effectivePrice) / spotPrice * 100%
```

Where `spotPrice = reserveOut / reserveIn`

### 4.4 Numerical Example

Pool: `x = 1000 A, y = 1000 B` → Price = 1 B/A

| Trade Size | Output | Effective Price | Price Impact |
|------------|--------|-----------------|--------------|
| 1 A | 0.999 B | 0.999 | 0.1% |
| 10 A | 9.91 B | 0.991 | 0.9% |
| 100 A | 90.9 B | 0.909 | 9.1% |
| 500 A | 333 B | 0.667 | 33.3% |

**Key insight**: Large trades relative to pool size cause significant price impact!

---

## 5. Comparison with Uniswap V2

### 5.1 Features Comparison

| Feature | Our AMM | Uniswap V2 |
|---------|---------|------------|
| Constant Product Formula | ✓ | ✓ |
| 0.3% Trading Fee | ✓ | ✓ |
| LP Tokens | ✓ | ✓ |
| Add Liquidity | ✓ | ✓ |
| Remove Liquidity | ✓ | ✓ |
| Swap | ✓ | ✓ |
| Slippage Protection | ✓ | ✓ |
| Flash Loans | ✗ | ✓ |
| Protocol Fee (0.05%) | ✗ | Optional |
| TWAP Oracles | ✗ | ✓ |
| Router Contract | ✗ | ✓ |
| Factory Contract | ✗ | ✓ |
| Migrator | ✗ | ✓ |

### 5.2 Missing Features Analysis

1. **Flash Loans**: Not implemented - allows borrowing tokens without collateral if returned in same transaction

2. **Protocol Fee**: Uniswap V2 allows 0.05% of swap fees to go to protocol (governance)

3. **TWAP Oracles**: Time-Weighted Average Price oracles for safer price feeds

4. **Factory Pattern**: Uniswap uses factory to create multiple pairs programmatically

5. **Router Contract**: Uniswap provides a router that handles multi-hop swaps andETH wrapping

### 5.3 Security Considerations

Our AMM is missing:
- Reentrancy guards
- Access controls
- Pausable functions
- Emergency withdraw
- Migration paths

These would be needed for production deployment.

---

## 6. Conclusion

The constant product AMM is elegant in its simplicity but powerful in its ability to create decentralized liquidity. Key takeaways:

1. **k increases** with each trade due to fees, benefitting LPs
2. **Impermanent loss** is the cost of providing passive liquidity
3. **Price impact** scales non-linearly with trade size
4. **Production AMMs** need additional features for security and usability

---

*Document prepared for Blockchain Technologies 2 - Assignment 2*
