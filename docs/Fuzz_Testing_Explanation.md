# Fuzz Testing vs Unit Testing

## Unit Testing

### Overview
Unit testing involves writing specific, predetermined test cases that verify individual functions or code paths. Each test has a fixed input and expected output.

### When to Use Unit Tests

1. **Known edge cases**: When you know specific scenarios that could cause bugs (e.g., zero address, overflow values)
2. **Business logic**: When you have specific requirements that must be met
3. **Initial development**: When building new features, unit tests help ensure basic functionality works
4. **Regression testing**: To catch bugs when making changes to existing code
5. **Fast feedback**: Unit tests run quickly, providing immediate feedback

### Advantages
- **Deterministic**: Same input always produces same result
- **Fast**: Can run thousands of tests in seconds
- **Specific**: Clear about what functionality is being tested
- **Easy to debug**: When a test fails, you know exactly what broke
- **Self-documenting**: Test names describe the expected behavior

### Disadvantages
- **Limited coverage**: Can't anticipate all possible inputs
- **Human bias**: Testers may miss edge cases
- **Maintenance**: Need to write new tests for new scenarios

---

## Fuzz Testing

### Overview
Fuzz testing (or fuzzing) automatically generates random inputs to find bugs. The testing framework tries thousands of random values to find edge cases the developer didn't anticipate.

### When to Use Fuzz Tests

1. **Unknown unknowns**: When you're not sure what could go wrong
2. **Input validation**: Testing how code handles unexpected or malicious inputs
3. **Security auditing**: Finding vulnerabilities in smart contracts
4. **Boundary testing**: Discovering what happens at edge of valid ranges
5. **After unit tests**: Adding fuzz tests to increase coverage

### Advantages
- **High coverage**: Tests thousands of inputs automatically
- **Finds edge cases**: Discovers unexpected behavior
- **Less bias**: Not limited by developer's imagination
- **Automated**: Requires less manual test writing

### Disadvantages
- **Non-deterministic**: May fail intermittently
- **Hard to reproduce**: Failed inputs need to be captured
- **Slower**: Need many runs for good coverage
- **Less readable**: Random inputs don't tell a story

---

## Comparison Table

| Aspect | Unit Tests | Fuzz Tests |
|--------|------------|------------|
| Input Selection | Manual | Random/Generated |
| Coverage | Limited to written cases | Broad, automatic |
| Speed | Fast | Slower |
| Reproducibility | Always reproducible | May need capture |
| Debugging | Easy | Harder |
| Best For | Business logic | Edge cases, security |

---

## Recommendation

Use **both**! A comprehensive test suite should include:

1. **Unit tests** for core functionality and known requirements
2. **Fuzz tests** to discover unknown edge cases
3. **Invariant tests** to verify properties that should always hold

This combination provides the best protection against bugs while maintaining fast feedback cycles.

---

## Foundry-specific Implementation

Foundry makes fuzz testing easy:

```solidity
// Fuzz test - Foundry auto-generates random values
function testFuzzTransfer(uint256 amount) public {
    amount = bound(amount, 0, token.balanceOf(address(this)));
    token.transfer(user1, amount);
    assertEq(token.balanceOf(user1), amount);
}
```

The `bound()` function constrains the random value to a valid range.

For invariant testing:

```solidity
// Invariant - should always hold
function invariantTotalSupplyConstant() public {
    assertEq(token.totalSupply(), INITIAL_SUPPLY);
}
```

Foundry runs thousands of random transactions and verifies the invariant holds in each case.
