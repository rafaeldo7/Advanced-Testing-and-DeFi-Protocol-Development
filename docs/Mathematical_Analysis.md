# Математический анализ AMM контракта

## 1. Постоянный продукт (Constant Product)

### Базовая формула

AMM использует формулу постоянного продукта:

$$x \cdot y = k$$

где:
- $x$ — резерв токена A
- $y$ — резерв токена B
- $k$ — инвариант (постоянная)

### Вывод формулы вывода

При обмене $\Delta x$ токенов A на $\Delta y$ токенов B:

$$(x + \Delta x) \cdot (y - \Delta y) = k'$$

Для сохранения инварианта (без комиссии):
$$(x + \Delta x)(y - \Delta y) = xy$$

Раскрываем:
$$xy - x \cdot \Delta y + y \cdot \Delta x - \Delta x \cdot \Delta y = xy$$

Упрощаем (пренебрегаем $\Delta x \cdot \Delta y$):
$$y \cdot \Delta x = x \cdot \Delta y$$

Откуда получаем формулу вывода:
$$\Delta y = \frac{y \cdot \Delta x}{x + \Delta x}$$

---

## 2. Учёт комиссии 0.3%

### Как работает комиссия

При обмене $\Delta x$ токенов A:

1. **Взимается комиссия**: $fee = \Delta x \cdot 0.003$
2. **Количество без комиссии**: $\Delta x_{net} = \Delta x - fee = \Delta x \cdot (1 - 0.003) = \Delta x \cdot 0.997$

### Формула вывода с комиссией

Реализовано в `getAmountOut`:

```solidity
uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE) / FEE_DENOMINATOR;
uint256 numerator = amountInWithFee * reserveOut;
uint256 denominator = reserveIn + amountInWithFee;
return numerator / denominator;
```

Математически:
$$\Delta y = \frac{y \cdot \Delta x_{net}}{x + \Delta x_{net}} = \frac{y \cdot \Delta x \cdot 0.997}{x + \Delta x \cdot 0.997}$$

### Влияние комиссии на инвариант k

После обмена инвариант увеличивается:

$$k_{new} = (x + \Delta x_{net}) \cdot (y - \Delta y)$$

Подставляем $\Delta y$:
$$k_{new} = (x + \Delta x_{net}) \cdot \left(y - \frac{y \cdot \Delta x_{net}}{x + \Delta x_{net}}\right)$$
$$k_{new} = (x + \Delta x_{net}) \cdot y - y \cdot \Delta x_{net} = xy + y \cdot \Delta x_{net} - y \cdot \Delta x_{net}$$

Упрощаем:
$$k_{new} = xy + y \cdot \Delta x_{net} - y \cdot \Delta x_{net} = xy$$

Подождите, это не совсем так. Давайте проведём точный анализ.

### Точный анализ изменения k

Исходное состояние: $(x, y)$, $k = xy$

После обмена $\Delta x$ (с комиссией $\Delta x_{fee}$):
- Резерв A: $x' = x + \Delta x_{net}$
- Резерв B: $y' = y - \Delta y$
- Новый инвариант: $k' = x'y'$

Где $\Delta x_{net} = \Delta x \cdot 0.997$ и $\Delta y = \frac{y \cdot \Delta x_{net}}{x + \Delta x_{net}}$

Подставляем:
$$k' = (x + \Delta x_{net}) \cdot \left(y - \frac{y \cdot \Delta x_{net}}{x + \Delta x_{net}}\right)$$
$$k' = y(x + \Delta x_{net}) - y \cdot \Delta x_{net}$$
$$k' = xy + y \cdot \Delta x_{net} - y \cdot \Delta x_{net}$$
$$k' = xy = k$$

На самом деле, **инвариант k остаётся постоянным** с точки зрения формулы! Комиссия не "увеличивает" k в смысле постоянного продукта - она просто остаётся в пуле как ликвидность.

**Реальный эффект комиссии**: комиссия $\Delta x_{fee}$ остаётся в пуле, увеличивая $x$ на эту величину. Это означает:

$$k_{new} = (x + \Delta x_{net} + \Delta x_{fee}) \cdot y = (x + \Delta x) \cdot y = k + \Delta x \cdot y$$

То есть **k увеличивается** на $\Delta x_{fee} \cdot y$, что создаёт доход для провайдеров ликвидности.

---

## 3. Impermanent Loss (Непостоянные потери)

### Определение

Impermanent Loss — это разница между:
1. Стоимостью токенов при удержании (HODL)
2. Стоимостью тех же токонов в пуле ликвидности

### Вывод формулы

**Начальное состояние** (t=0):
- Депозит: $P$ долларов в A и $P$ долларов в B
- Цена A = 1 USD, B = 1 USD
- Резервы: $(x, y) = (P, P)$
- Получено LP токенов: $L = \sqrt{P \cdot P} = P$

**Конечное состояние** (t=1):
- Цена A изменилась в $r$ раз
- Если $r > 1$, цена A выросла в $r$ раз
- Новая цена A = $r$ USD
- Соотношение резервов изменится для поддержания цены

Предположим, цена A выросла в $r$ раз. Для поддержания цены:
$$\frac{y}{x} = r \quad \Rightarrow \quad y = rx$$

Из постоянного продукта: $xy = k = P^2$

Подставляем: $x \cdot rx = P^2$

$$x^2 r = P^2 \quad \Rightarrow \quad x = \frac{P}{\sqrt{r}}$$
$$y = r \cdot \frac{P}{\sqrt{r}} = P\sqrt{r}$$

### Стоимость в пуле

При выводе ликвидности (100% LP токенов):
- Получаем A: $x_{withdraw} = x = \frac{P}{\sqrt{r}}$
- Получаем B: $y_{withdraw} = y = P\sqrt{r}$

**Стоимость в пуле в USD**:
$$Value_{AMM} = \frac{P}{\sqrt{r}} \cdot r + P\sqrt{r} \cdot 1 = P\sqrt{r} + P\sqrt{r} = 2P\sqrt{r}$$

### Стоимость при HODL

Если просто держать токены:
- Было: $P$ долларов в A, $P$ долларов в B
- A теперь стоит $r$ USD, B стоит 1 USD

**Стоимость HODL в USD**:
$$Value_{HODL} = P \cdot r + P \cdot 1 = P(r + 1)$$

### Вычисление Impermanent Loss

$$IL = Value_{AMM} - Value_{HODL}$$
$$IL = 2P\sqrt{r} - P(r + 1)$$
$$IL = P(2\sqrt{r} - r - 1)$$

**Относительный IL** (в процентах):
$$\frac{IL}{P} = 2\sqrt{r} - r - 1$$

### Примеры для разных сценариев

| Изменение цены r | IL (относительный) |
|------------------|---------------------|
| 0.5x (↓50%)      | +5.7%               |
| 0.75x (↓25%)     | +1.8%               |
| 1x (без изменений) | 0%                |
| 1.25x (↑25%)     | -1.8%               |
| 2x (↑100%)       | -5.7%               |
| 4x (↑300%)       | -13.4%              |
| 10x (↑900%)      | -37.2%              |

**Важно**: Знак "-" означает потерю относительно HODL.

### График IL

```
IL (%)
    │
  0 ─┼───────────────────────────────────────────────────
    │                    *
 -5 ─│               *
    │            *
-10 ─│        *
    │     *
-15 ─│   *
    │ *
-20 ─┼*
    │
    └──────┬──────┬──────┬──────┬──────┬──────→ r (x)
         0.5    1.0    2.0    4.0    10.0
```

---

## 4. Price Impact (Влияние на цену)

### Определение

Price Impact — это изменение цены пула при совершении сделки.

### Вывод формулы

**До сделки**: цена $P_{before} = \frac{y}{x}$

**После сделки** (обмен $\Delta x$ на $\Delta y$):
- Новый резерв A: $x' = x + \Delta x_{net}$
- Новый резерв B: $y' = y - \Delta y$
- Новая цена: $P_{after} = \frac{y'}{x'}$

### Пример расчёта

Пусть $x = 10000$ A, $y = 10000$ B, обмениваем $\Delta x = 100$ A.

С комиссией 0.3%:
$$\Delta x_{net} = 100 \cdot 0.997 = 99.7$$

$$\Delta y = \frac{10000 \cdot 99.7}{10000 + 99.7} = \frac{997000}{10099.7} \approx 98.7$$

**Цена до сделки**: $1$ B за 1 A
**Цена после сделки**: $\frac{10000 - 98.7}{10000 + 99.7} = \frac{9901.3}{10099.7} \approx 0.9803$ B за 1 A

**Price Impact**: $(1 - 0.9803) / 1 \approx 1.97\%$

### Формула для произвольного размера сделки

$$\text{Price Impact} = \frac{\Delta x_{net}}{x + \frac{\Delta x_{net}}{2}}$$

Для малых сделок ($\Delta x \ll x$):
$$\text{Price Impact} \approx \frac{\Delta x_{net}}{x}$$

### Зависимость Price Impact от размера пула

| Размер сделки (% от резерва) | Price Impact (0.3% fee) |
|-------------------------------|-------------------------|
| 0.1%                          | ~0.1%                   |
| 1%                            | ~1.0%                   |
| 10%                           | ~9.1%                   |
| 25%                           | ~20%                    |
| 50%                           | ~33%                    |

---

## 5. Ликвидность и LP токены

### Выпуск LP токенов

**Первый провайдер** (из `addLiquidity`):
$$L = \sqrt{amountA \cdot amountB}$$

Это следует из формулы постоянного продукта: если депозит содержит $a$ A и $b$ B по текущей цене, то $L = \sqrt{ab}$ обеспечивает справедливое распределение.

**Последующие провайдеры**:
$$L_{new} = L_{old} \cdot \min\left(\frac{\Delta x}{x}, \frac{\Delta y}{y}\right)$$

Это гарантирует, что провайдер получает LP токены пропорционально своей доле в пуле.

### Вывод ликвидности

При сгорании $l$ LP токенов:
- Получаем A: $\Delta x = \frac{l \cdot x}{L_{total}}$
- Получаем B: $\Delta y = \frac{l \cdot y}{L_{total}}$

---

## 6. Анализ безопасности

### integer overflow

Solidity 0.8+ автоматически проверяет на переполнение. Однако используется `sqrt` с ручной реализацией.

### Reentrancy protection

Контракт использует `nonReentrant` модификатор для `swap` и `removeLiquidity`.

### Front-running

AMM уязвимы к front-running, как и любые on-chain протоколы. Защита: использовать частные пулы или MEV-Protection.

---

## 7. Сравнение с Uniswap V2

| Параметр | Наш AMM | Uniswap V2 |
|----------|---------|------------|
| Формула | x*y=k | x*y=k |
| Комиссия | 0.3% | 0.3% |
| LP токены | Собственный | ERC-20 |
| Reentrancy guard | ✓ | ✗ |
| Oracle функций | ✓ | ✓ |

---

## 8. Заключение

Математика AMM обеспечивает:
- **Автоматическое ценообразование** на основе резервов
- **Комиссии** остаются в пуле, увеличивая доход LP
- **Impermanent Loss** — компромисс за возможность заработка на комиссиях
- **Price Impact** — защита от чрезмерно больших сделок

Ключевые формулы:
- Вывод: $\Delta y = \frac{y \cdot \Delta x \cdot 0.997}{x + \Delta x \cdot 0.997}$
- IL: $IL = 2\sqrt{r} - r - 1$
- Price Impact: $\approx \frac{\Delta x}{x}$ для малых сделок
