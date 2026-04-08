# Fork Testing Explanation

## What is Fork Testing?

Fork testing allows you to create a local copy of a blockchain network (mainnet or testnet) and run tests against it. Your tests interact with real, deployed contracts while the fork is isolated from the actual network.

## Key Functions

### vm.createSelectFork

```solidity
// Create a fork from RPC URL
uint256 forkId = vm.createFork("https://mainnet.infura.io/v3/YOUR_KEY");

// Create a fork at specific block number
uint256 forkId = vm.createFork("https://mainnet.infura.io/v3/YOUR_KEY", 15000000);

// Select the fork to use
vm.selectFork(forkId);
```

**How it works:**
1. Downloads state from the specified network at given block
2. Creates an isolated copy in memory
3. All transactions only affect this local copy, not the real network

### vm.rollFork

```solidity
// Roll to specific block number
vm.rollFork(16000000);

// Roll forward by delta
vm.rollFork(block.number + 100);
```

**How it works:**
1. Changes the "current block" in the fork
2. Simulates time passing on the network
3. Useful for testing time-dependent scenarios

## Benefits of Fork Testing

### 1. Real Contract Interactions
- Test against actual deployed protocols (Uniswap, Aave, etc.)
- No need to mock complex external contracts
- More realistic testing environment

### 2. Real Market Conditions
- Test with actual prices and liquidity
- Verify integration with real DeFi protocols
- Catch issues that only appear with real data

### 3. Cost-effective
- No need to deploy test contracts
- No gas costs
- Fast iteration without waiting for testnet

### 4. Reproducibility
- Fork at specific block for consistent tests
- Can share fork state between tests
- Deterministic results

## Limitations of Fork Testing

### 1. Network Dependency
- Requires RPC access to mainnet/testnet
- Can be slow (downloading state)
- May fail if RPC is down or rate-limited

### 2. State Isolation
- Fork state doesn't persist between test runs
- Can't test persistent state changes
- Each test starts fresh

### 3. Not Real Execution
- Some edge cases may differ from mainnet
- Block timestamp manipulation possible
- May miss network-level issues

### 4. Cost
- RPC provider costs can add up
- Large state downloads take time
- Storage usage on local machine

## Example: Testing Uniswap Integration

```solidity
function testSwapOnUniswap() public {
    // Fork mainnet
    uint256 forkId = vm.createFork("https://mainnet.infura.io/v3/KEY");
    vm.selectFork(forkId);
    
    // Get quote for swap
    IUniswapV2Router router = IUniswapV2Router(ROUTER_ADDRESS);
    uint[] memory amounts = router.getAmountsOut(1e18, path);
    
    // Execute swap (local only, no real funds)
    router.swapExactETHForTokens{value: 1e18}(...);
}
```

## Best Practices

1. **Cache forks**: Reuse forks across tests when possible
2. **Specify blocks**: Use specific block numbers for reproducibility
3. **Mock failures**: Test how your code handles reverts
4. **Use testnet**: Test on testnet first to avoid mainnet risks
5. **Environment variables**: Store RPC URLs in env, not in code

## When to Use Fork Testing

- Integration testing with external protocols
- Testing against real price feeds
- Verifying protocol upgrades
- Auditing security-critical code
- Reproducing mainnet bugs locally

---

## Плюсы и минусы Fork Testing

### Плюсы:

1. **Реальная интеграция** - Тестирование против реальных DeFi протоколов (Uniswap, Aave, Compound)
2. **Без моков** - Не нужно мокать сложные внешние контракты
3. **Реальные цены** - Использование реальных рыночных цен и ликвидности
4. **Высокая точность** - Более точные результаты чем юнит тесты с моками
5. **Обнаружение реальных багов** - Можно найти проблемы, которые не видны в изолированном тестировании

### Минусы:

1. **Зависимость от сети** - Требует доступ к RPC mainnet или testnet
2. **Скорость** - Может быть медленнее из-за сетевых вызовов
3. **Непостоянство** - Изменения состояния не сохраняются между тестами
4. **API ключи** - Может потребоваться платный RPC endpoint для продакшена
5. **Изменчивость** - Тесты могут сломаться если mainnet контракты изменятся

---

## Детальное объяснение ключевых функций

### vm.createSelectFork

```solidity
uint256 forkId = vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY");
```

Эта функция создаёт форк блокчейна и сразу переключает тесты на него:

1. **Создание форка** - Скачивает состояние сети с указанного RPC провайдера
2. **Локальная копия** - Создаёт изолированную копию состояния в памяти
3. **Автоматическое переключение** - Сразу делает этот форк активным
4. **Возвращает ID** - Уникальный идентификатор форка для последующего использования

Также можно указать конкретный блок:
```solidity
uint256 forkId = vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY", 19000000);
```

### vm.rollFork

```solidity
// Перемотка к конкретному блоку
vm.rollFork(19000000);

// Перемотка вперёд на N блоков
vm.rollFork(block.number + 100);
```

Эта функция перематывает время в форке:

1. **Изменение текущего блока** - Симулирует перемотку времени в блокчейне
2. **Тестирование time-sensitive логики** - Проверка кода, зависящего от времени
3. **Симуляция будущего** - Можно протестировать что произойдёт через N блоков
4. **Воспроизведение событий** - Вернуться к блоку где произошла ошибка
