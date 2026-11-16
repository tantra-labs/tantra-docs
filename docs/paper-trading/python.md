# Paper Trading — Python SDK

The `tantra.paper` module exposes the paper exchange to Python. `PaperSession`
drives the same `PaperExchange` engine as the backtester, the `paper serve` REST
daemon, the CLI, and the web panel — so a script that fills in `PaperSession`
behaves identically in `paper serve` and in the web panel given the same tape and
seed.

This page walks through the canonical, tested example
`tantra-examples/examples/basic/06_paper_trading.py`, covered by
`tantra-examples/tests/unit/test_06_paper_trading.py` (six tests, including
"two runs with the same seed are identical"). The snippet below is a faithful
excerpt of that example (the example wraps the same calls in a `run()` function
and JSON-serializes the result via its `serialize_fill` helper).

## Construct a seeded session

A `PaperSession` takes the initial `cash` and an optional `seed`. With a seed the
engine's latency model is deterministic: two runs with the same seed produce
identical fills and equity.

```python
from decimal import Decimal

from tantra.instrument import InstrumentId
from tantra.paper import PaperSession

session = PaperSession(cash=Decimal("1000000"), seed=7)
reliance = InstrumentId("RELIANCE", "NSE")
```

## Place a resting limit buy and a crossing market sell

Anchor the market price first (a market order with no contra liquidity is
rejected by the engine with `NoMarketPrice`), then let a limit buy rest in the
book and a market sell cross it:

```python
session.set_market_price(reliance, Decimal("100"))
buy_id = session.place_order(
    reliance, "BUY", Decimal("10"), order_type="LIMIT", limit_price=Decimal("100")
)
sell_id = session.place_order(reliance, "SELL", Decimal("10"), order_type="MARKET")
```

## Advance the engine clock

Matching happens when the engine's clock advances. There is no wall clock in the
engine — every transition takes an explicit timestamp:

```python
session.advance_to("2023-11-14T22:14:00Z")
```

## Read fills, equity, cash and positions

```python
for fill in session.fills():
    print(
        fill.fill_id,
        fill.order_id,
        fill.instrument.to_str(),
        str(fill.side),
        str(fill.price),
        str(fill.quantity),
        fill.timestamp,
    )
print("equity:", session.equity())
print("cash:", session.cash())
print("positions:", {str(k): str(v) for k, v in session.positions().items()})
```

Each fill carries a `fill_id`, the matching `order_id`, the instrument, side,
executed price and quantity, and the fill timestamp. Positions are derived from
fills — nothing is seeded.

## Full API surface

| Method | Purpose |
|--------|---------|
| `place_order(instrument, side, quantity, order_type="MARKET" \| "LIMIT", limit_price=None, trigger_price=None, tif="DAY", ts_iso="")` | Submit an order; `LIMIT` needs `limit_price`, stop orders need `trigger_price` |
| `cancel_order(...)` | Cancel a working order |
| `amend_order(...)` | Amend the price / quantity of a working order |
| `feed_bar(bar)` / `feed_tick(tick)` | Feed market data into the engine |
| `advance_to(ts_iso)` | Step the engine clock; matching happens on advance |
| `set_market_price(instrument, price)` | Anchor the last-trade price (used by market orders) |
| `fills()` / `events()` | Fill reports / order events |
| `positions()` / `cash()` / `equity()` | Current P&L state |
| `depth(instrument)` / `order(order_id)` | L2 book snapshot / order lookup |
| `run(strategy, bars)` | Strategy-driving loop mirroring `tantra.backtest.session.Session` |

The native `tantra.paper.PaperExchange` pyclass is also importable if you need the
raw engine instead of the session wrapper.

## Determinism notes

- **Same seed, same run** — compare runs with the *same* seed (that is what the
  tests do); a different seed changes the latency draws, though fills still land
  on the next advance.
- **Market order with no contra liquidity** — rejected by the engine
  (`NoMarketPrice`); place resting liquidity before the crossing order.
- **Paper, not a broker** — fills are simulated, there is no settlement, and
  positions are derived purely from fills.

See the [REST & WebSocket](rest-ws.md) page for the same engine behind a daemon,
and [Backtesting](../backtesting/index.md) for how the engine drives the
event-driven backtester.
