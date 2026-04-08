# Mathematical Analysis of the AMM Contract

## Executive Summary

This document provides a comprehensive mathematical analysis of the Constant Product Automated Market Maker (AMM) implemented in the project. The analysis covers the core formulas, fee mechanics, impermanent loss, price impact, and security considerations.

---

## 1. Constant Product Formula

### 1.1 Basic Formula

The AMM uses the constant product formula:

**x · y = k**

Where:
- x = Reserve of token A
- y = Reserve of token B
- k = Invariant (constant)

### 1.2 Derivation of Output Formula

When exchanging Δx tokens of A for Δy tokens of B:

**(x + Δx) · (y - Δy) = k'**

For invariant preservation (without fees):
**(x + Δx)(y - Δy) = xy**

Expanding:
**xy - x·Δy + y·Δx - Δx·Δy = xy**

Simplifying (neglecting Δx·Δy):
**y·Δx = x·Δy**

Therefore, the output formula:
**Δy = (y · Δx) / (x + Δx)**

---

## 2. Fee Mechanism (0.3%)

### 2.1 How Fees Work

When exchanging Δx tokens of A:

1. **Fee is charged**: fee = Δx × 0.003
2. **Net amount**: Δx_net = Δx - fee = Δx × 0.997

### 2.2 Output Formula with Fee

Implemented in `getAmountOut`:

```solidity
uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE) / FEE_DENOMINATOR;
uint256 numerator = amountInWithFee * reserveOut;
uint256 denominator = reserveIn + amountInWithFee;
return numerator / denominator;
```

Mathematically:
**Δy = (y · Δx_net) / (x + Δx_net) = (y · Δx · 0.997) / (x + Δx · 0.997)**

### 2.3 Effect on Invariant k

After a trade, the invariant increases:

**k_new = (x + Δx_net) · y = k + Δx_fee · y**

The fee Δx_fee remains in the pool as liquidity, increasing k and creating returns for liquidity providers.

---

## 3. Impermanent Loss

### 3.1 Definition

Impermanent Loss is the difference between:
1. Value of tokens when held (HODL)
2. Value of the same tokens in the liquidity pool

### 3.2 Formula Derivation

**Initial State (t=0):**
- Deposit: $P dollars in A and $P dollars in B
- Price A = 1 USD, B = 1 USD
- Reserves: (x, y) = (P, P)
- LP tokens received: L = √(P × P) = P

**Final State (t=1):**
- Price of A changed by factor r
- If r > 1, price of A increased r times
- New price A = r USD
- Reserves adjust to maintain price

Assuming A price increased by factor r. To maintain price:
**y / x = r → y = rx**

From constant product: xy = k = P²

Substituting: x · rx = P²

**x = P / √r**
**y = P√r**

### 3.3 Value in AMM

When withdrawing liquidity (100% LP tokens):
- Receive A: x_withdraw = P / √r
- Receive B: y_withdraw = P√r

**AMM Value in USD:**
Value_AMM = (P/√r) × r + (P√r) × 1 = P√r + P√r = **2P√r**

### 3.4 Value if HODLed

If simply holding tokens:
- Had: $P in A, $P in B
- A now costs r USD, B costs 1 USD

**HODL Value in USD:**
Value_HODL = P × r + P × 1 = **P(r + 1)**

### 3.5 Impermanent Loss Calculation

**IL = Value_AMM - Value_HODL**
**IL = 2P√r - P(r + 1)**
**IL = P(2√r - r - 1)**

**Relative IL (percentage):**
**IL/P = 2√r - r - 1**

### 3.6 Examples

| Price Change r | Relative IL |
|----------------|-------------|
| 0.5x (↓50%)    | +5.7%       |
| 0.75x (↓25%)   | +1.8%       |
| 1x (no change) | 0%          |
| 1.25x (↑25%)   | -1.8%       |
| 2x (↑100%)     | -5.7%       |
| 4x (↑300%)     | -13.4%      |
| 10x (↑900%)    | -37.2%      |

Note: Negative values indicate loss relative to HODL.

---

## 4. Price Impact

### 4.1 Definition

Price Impact is the change in pool price when executing a trade.

### 4.2 Formula Derivation

**Before trade**: Price = y/x

**After trade** (exchange Δx for Δy):
- New reserve A: x' = x + Δx_net
- New reserve B: y' = y - Δy
- New price: Price_after = y'/x'

### 4.3 Example Calculation

Given: x = 10000 A, y = 10000 B, exchange Δx = 100 A

With 0.3% fee:
**Δx_net = 100 × 0.997 = 99.7**

**Δy = (10000 × 99.7) / (10000 + 99.7) = 997000 / 10099.7 ≈ 98.7**

**Price before trade**: 1 B per 1 A
**Price after trade**: (10000 - 98.7) / (10000 + 99.7) = 9901.3 / 10099.7 ≈ 0.9803 B per 1 A

**Price Impact**: (1 - 0.9803) / 1 ≈ **1.97%**

### 4.4 Formula for Arbitrary Trade Size

**Price Impact = Δx_net / (x + Δx_net/2)**

For small trades (Δx << x):
**Price Impact ≈ Δx_net / x**

### 4.5 Price Impact vs Pool Size

| Trade Size (% of reserve) | Price Impact (0.3% fee) |
|---------------------------|------------------------|
| 0.1%                     | ~0.1%                  |
| 1%                       | ~1.0%                  |
| 10%                      | ~9.1%                  |
| 25%                      | ~20%                   |
| 50%                      | ~33%                   |

---

## 5. Liquidity and LP Tokens

### 5.1 LP Token Minting

**First provider** (from addLiquidity):
**L = √(amountA × amountB)**

This follows from constant product formula: if deposit contains a A and b B at current price, L = √(ab) ensures fair distribution.

**Subsequent providers:**
**L_new = L_old × min(Δx/x, Δy/y)**

This ensures the provider receives LP tokens proportional to their share in the pool.

### 5.2 Liquidity Withdrawal

When burning l LP tokens:
- Receive A: Δx = (l × x) / L_total
- Receive B: Δy = (l × y) / L_total

---

## 6. Security Analysis

### 6.1 Integer Overflow

Solidity 0.8+ automatically checks for overflow. However, sqrt function uses manual implementation.

### 6.2 Reentrancy Protection

The contract uses `nonReentrant` modifier for `swap` and `removeLiquidity` functions.

### 6.3 Front-Running

AMMs are vulnerable to front-running, like any on-chain protocol. Protection: use private pools or MEV-Protection.

### 6.4 Slippage Protection

The contract includes minAmountOut parameters in swap and removeLiquidity functions to protect against slippage.

---

## 7. Comparison with Uniswap V2

| Parameter        | Our AMM    | Uniswap V2 |
|------------------|------------|------------|
| Formula          | x*y=k      | x*y=k      |
| Fee              | 0.3%       | 0.3%       |
| LP Tokens        | Custom     | ERC-20     |
| Reentrancy Guard| ✓          | ✗          |
| Oracle Functions| ✓          | ✓          |

---

## 8. Key Formulas Summary

| Concept | Formula |
|---------|---------|
| Output Amount | Δy = (y · Δx · 0.997) / (x + Δx · 0.997) |
| Impermanent Loss | IL = 2√r - r - 1 |
| Price Impact (small) | ≈ Δx / x |
| LP Minting (first) | L = √(amountA × amountB) |
| LP Minting (subsequent) | L_new = L × min(Δx/x, Δy/y) |

---

## 9. Conclusion

The AMM mathematics provides:

- **Automatic pricing** based on reserves
- **Fees** remain in the pool, increasing LP returns
- **Impermanent Loss** is the trade-off for earning swap fees
- **Price Impact** protects against excessively large trades

The implementation correctly handles:
- Constant product formula with 0.3% fee
- Fair LP token distribution
- Slippage protection
- Reentrancy protection

This creates a fully functional AMM similar to Uniswap V2, suitable for educational purposes and as a foundation for DeFi applications.

---

## References

1. Uniswap V2 Documentation: https://docs.uniswap.org/
2. Ethereum Whitepaper: https://ethereum.org/whitepaper/
3. Solidity Documentation: https://docs.soliditylang.org/

---

*Document generated for Blockchain Technologies 2 - Assignment 2*
*AMM Implementation with Constant Product Formula*
