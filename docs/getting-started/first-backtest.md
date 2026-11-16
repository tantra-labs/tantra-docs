# Your First Backtest

This walkthrough runs a 10/30 SMA crossover on synthetic RELIANCE bars,
offline, with no broker credentials and no data downloads. It uses the wheel
session orchestrator (`Tantra.backtest`) — the same path production workflows
use.

## The Strategy

Create `first_backtest.py`:

```python
from decimal import Decimal

from tantra import Strategy
from tantra.indicators import Sma
from tantra.backtest.session import Tantra


class SmaCrossover(Strategy):
    name = "sma_crossover"

    def __init__(self, fast: int = 10, slow: int = 30):
        super().__init__()
        self.fast = Sma(fast)
        self.slow = Sma(slow)

    def on_bar(self, bar) -> None:
        f = self.fast.update(bar.close)
        s = self.slow.update(bar.close)
        if f is None or s is None:
            return                     # never signal on a partial window
        pos = self.position(bar.instrument_id)
        if f > s and pos <= 0:
            self.buy(bar.instrument_id, Decimal("10"))
        elif f < s and pos > 0:
            self.sell(bar.instrument_id, pos)
```

## The Data

`Tantra.backtest` needs `bars=` or a `data=` provider. For a first run, use
the examples' synthetic bar generator — a straight-line ramp you control, so
the result is identical on every machine:

```python
from tantra_examples.synthetic import trending_bars

symbol = "RELIANCE"
bars = trending_bars(symbol, 120)      # 120 daily bars starting at ₹2500
```

(With a real provider, pass `data=` and `start=`/`end=` instead — see
[Loading Data](loading-data.md).)

## Running It

```python
result = Tantra.backtest(
    SmaCrossover(),
    symbol=symbol,
    exchange="NSE",
    bars=bars,
    cash=1_000_000,
    algo_id="my-first-backtest",
).run()

print(result.strategy_name)
print(result.metrics)
```

```bash
source .venv/bin/activate
python first_backtest.py
```

Expected output shape (numbers will differ — it is a synthetic ramp):

```text
sma_crossover
{'total_return_pct': 5.2, 'max_drawdown_pct': -0.8,
 'final_equity': 1052000.0, 'n_fills': 6, 'n_trades': 6}
```

## What Just Happened

The session orchestrator wired up, in order:

1. **Next-open fill simulation** — every market order fills at the **next**
   session's open, so a buy placed on bar *k* can never fill at bar *k*'s
   open (causal execution timing).
2. **Indian delivery costs** — the default cost model is
   `india.equity.delivery` (STT, exchange fees, GST, stamp duty, statutory
   levies), applied per fill.
3. **T+N settlement** — cash settles on the configured settlement lag.
4. **Exact Decimal accounting** — cash and positions are `decimal.Decimal`
   throughout; `float` appears only at the metrics/equity-curve boundary.

## Inspecting the Result

```python
result.metrics          # total_return_pct, max_drawdown_pct, final_equity, n_fills
result.equity_curve     # [(ts, equity), ...]
```

For fills, orders, and events at the compiled level, use the low-level
`tantra.run` path (every order is validated by the SEBI pre-trade risk
gate):

```python
from tantra import run
summary = run(SmaCrossover(), bars, algo_id="my-first-backtest")
print(summary.summary())   # Backtest(algo=...): bars=... orders_filled=... refusals=...
```

## Next Steps

- **[Loading Data](loading-data.md)** — synthetic vs. lakehouse vs. Parquet
  bar files.
- **[User Guide → Python SDK](../user-guide/python.md)** — the full SDK
  surface (indicators, paper sessions, adapters).
- **[Cost Modeling](../backtesting/cost_modeling.md)** — how the Indian
  equity cost model is defined and how to customize it.
- **[Avoiding Backtest Biases](../backtesting/avoiding_backtest_biases.md)** —
  how to tell if a 5% result on a synthetic ramp is real or an artifact.
