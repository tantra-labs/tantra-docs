# Python SDK

The `tantra` PyPI wheel (built by `tantra-ffi` via PyO3) is the Python-first
surface: exact-`Decimal` domain types, the SEBI pre-trade risk gate, a
compiled `StrategyRunner`, the `Tantra.backtest` session orchestrator, 100+
indicators, Arrow zero-copy data bridges, and the paper exchange. It is where
strategy authoring and research happen.

```python
import tantra
from tantra import Strategy, Parameter
from tantra.indicators import Sma
```

## Where It Lives

After `make prepare` the wheel is built with `maturin develop` into the
single workspace venv (`.venv`). Activate it:

```bash
source .venv/bin/activate
python -c "import tantra; print(tantra.__version__)"
```

The wheel also ships a tiny CLI:

```bash
python -m tantra.cli version
python -m tantra.cli backtest --bars-json bars.json --strategy mymod:MyStrategy
```

## Writing a Strategy

Subclass `Strategy`, override the lifecycle callbacks, and issue orders with
`self.buy` / `self.sell`. Quantities and prices are exact `Decimal`.

```python
from decimal import Decimal
from tantra import Strategy
from tantra.indicators import Sma

class SmaCrossover(Strategy):
    name = "sma_crossover"

    def __init__(self, fast: int = 10, slow: int = 30):
        super().__init__()
        self.fast = Sma(fast)
        self.slow = Sma(slow)

    def on_start(self) -> None:
        pass

    def on_bar(self, bar) -> None:
        f = self.fast.update(bar.close)
        s = self.slow.update(bar.close)
        if f is None or s is None:
            return
        pos = self.position(bar.instrument_id)
        if f > s and pos <= 0:
            self.buy(bar.instrument_id, Decimal("10"))
        elif f < s and pos > 0:
            self.sell(bar.instrument_id, pos)
```

`Parameter(default, min, max, step)` declares tunable hyper-parameters with
bounds validation (`Parameter.int(...)` for integer parameters).

## Running a Backtest

The session orchestrator is `Tantra.backtest` (from
`tantra.backtest.session`) — next-open fills, NSE delivery costs, T+N
settlement, exact Decimal accounting:

```python
from tantra.backtest.session import Tantra

result = Tantra.backtest(
    SmaCrossover(),
    symbol="RELIANCE",
    exchange="NSE",
    start="2024-01-01",
    end="2024-12-31",
    cash=1_000_000,
).run()

print(result.metrics)          # total_return_pct, max_drawdown_pct, final_equity, n_fills
print(result.equity_curve)     # [(ts, equity), ...]
```

`Tantra.backtest` accepts `bars=` to run over explicit bars, or a `data=`
`DataProvider` with `.bars(instrument_id, timeframe=..., start=..., end=...)`.
Remaining keyword arguments pass through to the simulator
(`long_only`, `as_of`, `lot_sizes`, `impact`, `auction`).

There is also a low-level compiled path — `tantra.strategy.run(strategy,
bars, algo_id=...)` — that runs the strategy through the compiled
`StrategyRunner` so **every order is validated by the SEBI pre-trade risk
gate**:

```python
from tantra import run
result = run(SmaCrossover(), bars, algo_id="my-algo")
print(result.summary())
```

## Data

| Source | How | Docs |
|:-------|:----|:-----|
| Synthetic bars (no downloads) | `tantra_examples.synthetic` helpers (`trending_bars`, `bar`, `weekdays`) | [First Backtest](../getting-started/first-backtest.md) |
| Parquet bar files | `SYMBOL.EXCHANGE.parquet` files fed to `tantra serve` | [REST API Workflows](rest-api.md) |
| Lakehouse / bhavcopy / corporate actions | `tantra-data` package (DuckDB + Parquet catalog) | [Data Lakehouse](../india/universes.md) |
| Arrow / Polars | `tantra.data.bars_to_arrow`, `bars_to_polars` | — |

## Indicators

Indicators live under `tantra.indicators` and stream tick-by-tick:

```python
from tantra.indicators import Sma, Ema, Rma, Wma, RSI, EMA

sma = Sma(20)
value = sma.update(Decimal("2510.50"))   # None until the window is warm
sma.crosses_above(other_sma)
```

`make_ma(kind, period, ...)` builds a moving average by name; the legacy
`SMA`/`EMA`/`RSI` aliases from the compiled registry are also exported.

## Paper Trading in Python

`tantra.paper.PaperSession` drives strategies or raw orders onto the
deterministic paper exchange — see
[Paper Trading → Python SDK](../paper-trading/python.md).

## Broker Adapters

`tantra-adapters` is a separate Python package (7 broker modules: Dhan,
Zerodha, Angel One, Upstox, Fyers, Kotak, IIFL; REST-only, Decimal-only,
with a deterministic `PaperBroker` for offline tests). See
[Adapters Package](../api/adapters-package.md) and
[Adapter Configuration](../india/adapter_configuration.md).

## Zero-Floats Rule

Prices, quantities, cash, and statutory costs are **always** `decimal.Decimal`
in this SDK — never `float`. The `_tantra` boundary accepts strings for
compiled types; `tantra.to_decimal(...)` and `tantra.instrument_id(...)`
are the canonical converters.
